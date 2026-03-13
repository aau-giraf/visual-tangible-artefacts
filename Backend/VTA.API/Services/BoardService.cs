using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Default implementation of <see cref="IBoardService"/>.
/// Encapsulates board CRUD, artefact layout management, and board clearing/deletion.
/// Unifies logic previously duplicated across BoardsController and SavedArtefactsController.
/// Registered as scoped in DI.
/// </summary>
public class BoardService : IBoardService
{
    private readonly VTAContext _context;
    private readonly ILogger<BoardService> _logger;

    public BoardService(VTAContext context, ILogger<BoardService> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<List<SavedBoard>> GetBoardsForUserAsync(int userId, int? skip = null, int? take = null)
    {
        var query = _context.SavedBoards
            .Where(b => b.UserId == userId)
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .OrderByDescending(b => b.ModifiedDate ?? b.CreatedDate);

        if (skip.HasValue || take.HasValue)
        {
            var resolvedSkip = Math.Max(skip ?? 0, 0);
            var resolvedTake = Math.Clamp(take ?? 50, 1, 200);
            return await query.Skip(resolvedSkip).Take(resolvedTake).ToListAsync();
        }

        return await query.ToListAsync();
    }

    /// <inheritdoc />
    public async Task<List<SavedBoard>> GetBoardListAsync(int userId, int? skip = null, int? take = null)
    {
        var query = _context.SavedBoards
            .Where(b => b.UserId == userId)
            .OrderByDescending(b => b.ModifiedDate ?? b.CreatedDate);

        if (skip.HasValue || take.HasValue)
        {
            var resolvedSkip = Math.Max(skip ?? 0, 0);
            var resolvedTake = Math.Clamp(take ?? 50, 1, 200);
            return await query.Skip(resolvedSkip).Take(resolvedTake).ToListAsync();
        }

        return await query.ToListAsync();
    }

    /// <inheritdoc />
    public async Task<SavedBoard?> GetBoardAsync(string boardId, int userId)
    {
        return await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .FirstOrDefaultAsync();
    }

    /// <inheritdoc />
    public async Task<SavedBoard> CreateBoardAsync(
        int userId, string name, List<BoardArtefactLayoutDTO>? artefacts = null)
    {
        if (artefacts != null && artefacts.Count > 0)
        {
            return await CreateBoardWithArtefactsAsync(userId, name, artefacts);
        }

        // Simple board creation (no artefacts)
        var board = new SavedBoard
        {
            Id = Guid.NewGuid().ToString(),
            Name = name,
            UserId = userId,
            CreatedDate = DateTime.UtcNow
        };

        _context.SavedBoards.Add(board);
        await _context.SaveChangesAsync();

        // Re-fetch with navigation properties
        return (await _context.SavedBoards
            .Include(b => b.SavedArtefacts)
                .ThenInclude(sa => sa.Artefact)
            .FirstOrDefaultAsync(b => b.Id == board.Id))!;
    }

    /// <inheritdoc />
    public async Task<SavedBoard?> UpdateBoardAsync(
        string boardId, int userId, string name, List<BoardArtefactLayoutDTO> artefacts)
    {
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
            .FirstOrDefaultAsync();

        if (board == null) return null;

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                board.Name = name;
                board.ModifiedDate = DateTime.UtcNow;

                // Keep existing saved artefacts, append new ones
                var artefactIds = board.SavedArtefacts.Select(sa => sa.ArtefactId).ToList();
                var savedArtefactIds = board.SavedArtefacts.Select(sa => sa.Id).ToList();

                foreach (var layout in artefacts)
                {
                    var artefactExists = await _context.Artefacts
                        .AnyAsync(a => a.ArtefactId == layout.ArtefactId && a.UserId == userId);

                    if (!artefactExists)
                    {
                        throw new InvalidOperationException(
                            $"Artefact {layout.ArtefactId} not found or doesn't belong to user");
                    }

                    var savedArtefact = new SavedArtefact
                    {
                        Id = Guid.NewGuid().ToString(),
                        ArtefactId = layout.ArtefactId,
                        BoardId = board.Id,
                        PosX = layout.PosX,
                        PosY = layout.PosY,
                        Width = layout.Width,
                        Height = layout.Height,
                        CreatedDate = DateTime.UtcNow
                    };

                    _context.SavedArtefacts.Add(savedArtefact);
                    artefactIds.Add(layout.ArtefactId);
                    savedArtefactIds.Add(savedArtefact.Id);
                }

                board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
                board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
                _context.SavedBoards.Update(board);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Re-fetch with navigation
                return await _context.SavedBoards
                    .Where(b => b.Id == board.Id)
                    .Include(b => b.SavedArtefacts)
                    .FirstOrDefaultAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });
    }

    /// <inheritdoc />
    public async Task<bool> PatchBoardAsync(string boardId, int userId, string? name, string? snapshotPath)
    {
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .FirstOrDefaultAsync();

        if (board == null) return false;

        if (!string.IsNullOrEmpty(name))
        {
            board.Name = name;
        }
        if (snapshotPath != null)
        {
            board.SnapshotPath = snapshotPath;
        }

        board.ModifiedDate = DateTime.UtcNow;
        _context.Entry(board).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await _context.SavedBoards.AnyAsync(b => b.Id == boardId))
                return false;
            throw;
        }

        return true;
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> UpdateArtefactLayoutAsync(
        string boardId, int userId, UpdateArtefactLayoutDTO request)
    {
        var boardExists = await _context.SavedBoards
            .AnyAsync(b => b.Id == boardId && b.UserId == userId);

        if (!boardExists)
            return (false, "NotFound");

        SavedArtefact? savedArtefact = null;

        // Try to find by SavedArtefactId first
        if (!string.IsNullOrEmpty(request.SavedArtefactId))
        {
            savedArtefact = await _context.SavedArtefacts
                .FirstOrDefaultAsync(sa => sa.Id == request.SavedArtefactId && sa.BoardId == boardId);
        }

        // Fall back to finding by ArtefactId
        if (savedArtefact == null)
        {
            savedArtefact = await _context.SavedArtefacts
                .FirstOrDefaultAsync(sa => sa.BoardId == boardId && sa.ArtefactId == request.ArtefactId);
        }

        // Upsert: create new if not found
        if (savedArtefact == null)
        {
            var artefactExists = await _context.Artefacts
                .AnyAsync(a => a.ArtefactId == request.ArtefactId && a.UserId == userId);

            if (!artefactExists)
                return (false, "BadRequest");

            savedArtefact = new SavedArtefact
            {
                Id = Guid.NewGuid().ToString(),
                ArtefactId = request.ArtefactId,
                BoardId = boardId,
                PosX = request.PosX,
                PosY = request.PosY,
                Width = request.Width,
                Height = request.Height,
                CreatedDate = DateTime.UtcNow
            };

            _context.SavedArtefacts.Add(savedArtefact);

            // Update board JSON ID-lists
            var board = await _context.SavedBoards.FindAsync(boardId);
            if (board != null)
            {
                var artefactIdsList = await _context.SavedArtefacts
                    .Where(sa => sa.BoardId == boardId)
                    .Select(sa => sa.ArtefactId)
                    .ToListAsync();
                var savedInstanceIds = await _context.SavedArtefacts
                    .Where(sa => sa.BoardId == boardId)
                    .Select(sa => sa.Id)
                    .ToListAsync();

                if (!artefactIdsList.Contains(savedArtefact.ArtefactId))
                    artefactIdsList.Add(savedArtefact.ArtefactId);
                if (!savedInstanceIds.Contains(savedArtefact.Id))
                    savedInstanceIds.Add(savedArtefact.Id);

                board.ArtefactIds = artefactIdsList.Count > 0 ? JsonSerializer.Serialize(artefactIdsList) : null;
                board.SavedArtefactIds = savedInstanceIds.Count > 0 ? JsonSerializer.Serialize(savedInstanceIds) : null;
                _context.SavedBoards.Update(board);
            }
        }
        else
        {
            savedArtefact.PosX = request.PosX;
            savedArtefact.PosY = request.PosY;
            savedArtefact.Width = request.Width;
            savedArtefact.Height = request.Height;
        }

        // Update board modified date
        var boardEntity = await _context.SavedBoards.FindAsync(boardId);
        if (boardEntity != null)
        {
            boardEntity.ModifiedDate = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return (true, null);
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> UpdateSavedArtefactLayoutAsync(
        string boardId, int userId, UpdateArtefactLayoutDTO request)
    {
        var boardExists = await _context.SavedBoards
            .AnyAsync(b => b.Id == boardId && b.UserId == userId);

        if (!boardExists)
            return (false, "NotFound");

        if (string.IsNullOrEmpty(request.SavedArtefactId))
            return (false, "BadRequest");

        var savedArtefact = await _context.SavedArtefacts
            .FirstOrDefaultAsync(sa => sa.Id == request.SavedArtefactId && sa.BoardId == boardId);

        if (savedArtefact == null)
            return (false, "NotFound");

        bool hasChanges = savedArtefact.PosX != request.PosX ||
                         savedArtefact.PosY != request.PosY ||
                         savedArtefact.Width != request.Width ||
                         savedArtefact.Height != request.Height;

        if (hasChanges)
        {
            savedArtefact.PosX = request.PosX;
            savedArtefact.PosY = request.PosY;
            savedArtefact.Width = request.Width;
            savedArtefact.Height = request.Height;

            var board = await _context.SavedBoards.FindAsync(boardId);
            if (board != null)
            {
                board.ModifiedDate = DateTime.UtcNow;
            }
        }

        await _context.SaveChangesAsync();
        return (true, null);
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> RemoveArtefactFromBoardAsync(
        string boardId, string savedArtefactId, int userId)
    {
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
            .FirstOrDefaultAsync();

        if (board == null)
            return (false, "NotFound");

        var toRemove = board.SavedArtefacts.FirstOrDefault(sa => sa.Id == savedArtefactId);
        if (toRemove == null)
            return (false, "NotFound");

        _context.SavedArtefacts.Remove(toRemove);

        // Rebuild JSON ID-lists
        var remaining = board.SavedArtefacts.Where(sa => sa.Id != savedArtefactId).ToList();
        var artefactIds = remaining.Select(sa => sa.ArtefactId).ToList();
        var savedArtefactIds = remaining.Select(sa => sa.Id).ToList();

        board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
        board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
        board.ModifiedDate = DateTime.UtcNow;

        _context.SavedBoards.Update(board);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> ClearBoardAsync(
        string boardId, int userId, bool deleteSessionArtefacts = false)
    {
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
            .FirstOrDefaultAsync();

        if (board == null)
            return (false, "NotFound");

        // Optionally delete Session-Artefact category artefacts
        if (deleteSessionArtefacts && board.SavedArtefacts.Any())
        {
            var artefactIdsOnBoard = board.SavedArtefacts
                .Select(sa => sa.ArtefactId)
                .Where(id => !string.IsNullOrEmpty(id))
                .ToList();

            if (artefactIdsOnBoard.Any())
            {
                var sessionArtefacts = await _context.Artefacts
                    .Where(a => artefactIdsOnBoard.Contains(a.ArtefactId)
                             && a.UserId == userId
                             && a.CategoryId == "Session-Artefact")
                    .ToListAsync();

                if (sessionArtefacts.Any())
                {
                    _context.Artefacts.RemoveRange(sessionArtefacts);
                }
            }
        }

        if (board.SavedArtefacts.Any())
        {
            _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
        }

        board.ArtefactIds = null;
        board.SavedArtefactIds = null;
        board.ModifiedDate = DateTime.UtcNow;
        _context.SavedBoards.Update(board);

        await _context.SaveChangesAsync();
        return (true, null);
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> DeleteBoardAsync(string boardId, int userId)
    {
        var board = await _context.SavedBoards
            .Where(b => b.Id == boardId && b.UserId == userId)
            .Include(b => b.SavedArtefacts)
            .FirstOrDefaultAsync();

        if (board == null)
            return (false, "NotFound");

        _context.SavedArtefacts.RemoveRange(board.SavedArtefacts);
        _context.SavedBoards.Remove(board);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    // ── Private helpers ────────────────────────────────────────────────

    private async Task<SavedBoard> CreateBoardWithArtefactsAsync(
        int userId, string name, List<BoardArtefactLayoutDTO> artefacts)
    {
        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var board = new SavedBoard
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = name,
                    UserId = userId,
                    CreatedDate = DateTime.UtcNow
                };

                _context.SavedBoards.Add(board);
                await _context.SaveChangesAsync();

                var artefactIds = new List<string>();
                var savedArtefactIds = new List<string>();

                foreach (var layout in artefacts)
                {
                    var artefactExists = await _context.Artefacts
                        .AnyAsync(a => a.ArtefactId == layout.ArtefactId && a.UserId == userId);

                    if (!artefactExists)
                    {
                        throw new InvalidOperationException(
                            $"Artefact {layout.ArtefactId} not found or doesn't belong to user");
                    }

                    static float Clamp(float v)
                    {
                        if (float.IsNaN(v) || float.IsInfinity(v)) return 0f;
                        return v;
                    }

                    var savedArtefact = new SavedArtefact
                    {
                        Id = Guid.NewGuid().ToString(),
                        ArtefactId = layout.ArtefactId,
                        BoardId = board.Id,
                        PosX = Clamp(layout.PosX),
                        PosY = Clamp(layout.PosY),
                        Width = Clamp(layout.Width),
                        Height = Clamp(layout.Height),
                        CreatedDate = DateTime.UtcNow
                    };

                    _context.SavedArtefacts.Add(savedArtefact);
                    artefactIds.Add(layout.ArtefactId);
                    savedArtefactIds.Add(savedArtefact.Id);
                }

                board.ArtefactIds = artefactIds.Count > 0 ? JsonSerializer.Serialize(artefactIds) : null;
                board.SavedArtefactIds = savedArtefactIds.Count > 0 ? JsonSerializer.Serialize(savedArtefactIds) : null;
                _context.SavedBoards.Update(board);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                // Re-fetch with navigation
                return (await _context.SavedBoards
                    .Where(b => b.Id == board.Id)
                    .Include(b => b.SavedArtefacts)
                        .ThenInclude(sa => sa.Artefact)
                    .FirstOrDefaultAsync())!;
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });
    }
}
