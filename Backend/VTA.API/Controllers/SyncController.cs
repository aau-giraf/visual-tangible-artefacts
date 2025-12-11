using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.Data.DbContexts;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for handling synchronization of changes
/// </summary>
[Authorize]
[Route("api/Users/Sync")]
[ApiController]
public class SyncController : ControllerBase
{
    private readonly VTAContext _context;

    /// <summary>
    /// Constructor for SyncController
    /// </summary>
    /// <param name="context">Database context</param>
    public SyncController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all changes (artefacts and boards) since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string (e.g., 2024-11-27T12:00:00Z)</param>
    /// <returns>List of all changed files</returns>
    [HttpGet("changes")]
    public async Task<ActionResult<SyncResponseDTO>> GetChanges([FromQuery] DateTime since)
    {
        Console.WriteLine($"[SYNC-API] GetChanges called with since: {since:O}");
        
        var userId = User.FindFirst("id")?.Value;
        Console.WriteLine($"[SYNC-API] User ID from token: {userId}");
        
        if (string.IsNullOrEmpty(userId))
        {
            Console.WriteLine("[SYNC-API] ERROR: No user ID in token, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        var changedFiles = new List<FileChangeDTO>();

        // Get changed artefacts
        Console.WriteLine($"[SYNC-API] Querying artefacts modified after {since:O} for user {userId}");
        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .ToListAsync();
        Console.WriteLine($"[SYNC-API] Found {artefacts.Count} changed artefacts");

        foreach (var artefact in artefacts)
        {
            var dto = new FileChangeDTO
            {
                FileId = artefact.ArtefactId,
                FileName = artefact.Name ?? "Unnamed Artefact",
                FileType = "artefact",
                ModifiedDate = artefact.ModifiedDate,
                ImageUrl = artefact.ImagePath != null 
                    ? $"{Request.Scheme}://{Request.Host}/api/assets/artefacts/{artefact.ImagePath}"
                    : null,
                SoundUrl = artefact.SoundPath != null
                    ? $"{Request.Scheme}://{Request.Host}/api/assets/sounds/{artefact.SoundPath}"
                    : null
            };
            changedFiles.Add(dto);
            Console.WriteLine($"[SYNC-API]   - Artefact: {dto.FileName} ({dto.FileId}), modified: {dto.ModifiedDate:O}");
        }

        // Get changed boards
        Console.WriteLine($"[SYNC-API] Querying boards modified after {since:O} for user {userId}");
        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .ToListAsync();
        Console.WriteLine($"[SYNC-API] Found {boards.Count} changed boards");

        foreach (var board in boards)
        {
            var dto = new FileChangeDTO
            {
                FileId = board.Id,
                FileName = board.Name,
                FileType = "board",
                ModifiedDate = board.ModifiedDate
            };
            changedFiles.Add(dto);
            Console.WriteLine($"[SYNC-API]   - Board: {dto.FileName} ({dto.FileId}), modified: {dto.ModifiedDate:O}");
        }

        // Sort by modified date (most recent first)
        Console.WriteLine($"[SYNC-API] Sorting {changedFiles.Count} total changes by modified date");
        changedFiles = changedFiles
            .OrderByDescending(f => f.ModifiedDate)
            .ToList();

        var response = new SyncResponseDTO
        {
            ChangedFiles = changedFiles,
            CheckDate = DateTime.UtcNow,
            TotalChanges = changedFiles.Count
        };
        
        Console.WriteLine($"[SYNC-API] Returning response: {response.TotalChanges} total changes, check date: {response.CheckDate:O}");
        return Ok(response);
    }

    /// <summary>
    /// Get only changed artefacts since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string</param>
    /// <returns>List of changed artefacts</returns>
    [HttpGet("artefacts")]
    public async Task<ActionResult<IEnumerable<FileChangeDTO>>> GetChangedArtefacts([FromQuery] DateTime since)
    {
        Console.WriteLine($"[SYNC-API] GetChangedArtefacts called with since: {since:O}");
        
        var userId = User.FindFirst("id")?.Value;
        Console.WriteLine($"[SYNC-API] User ID: {userId}");
        
        if (string.IsNullOrEmpty(userId))
        {
            Console.WriteLine("[SYNC-API] ERROR: No user ID, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        Console.WriteLine($"[SYNC-API] Querying artefacts for user {userId} modified after {since:O}");
        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .OrderByDescending(a => a.ModifiedDate)
            .ToListAsync();
        Console.WriteLine($"[SYNC-API] Found {artefacts.Count} changed artefacts");

        var changes = artefacts.Select(a => new FileChangeDTO
        {
            FileId = a.ArtefactId,
            FileName = a.Name ?? "Unnamed Artefact",
            FileType = "artefact",
            ModifiedDate = a.ModifiedDate,
            ImageUrl = a.ImagePath != null 
                ? $"{Request.Scheme}://{Request.Host}/api/assets/artefacts/{a.ImagePath}"
                : null,
            SoundUrl = a.SoundPath != null
                ? $"{Request.Scheme}://{Request.Host}/api/assets/sounds/{a.SoundPath}"
                : null
        }).ToList();

        foreach (var change in changes)
        {
            Console.WriteLine($"[SYNC-API]   - {change.FileName} ({change.FileId}), modified: {change.ModifiedDate:O}");
        }

        Console.WriteLine($"[SYNC-API] Returning {changes.Count} changed artefacts");
        return Ok(changes);
    }

    /// <summary>
    /// Get only changed boards since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string</param>
    /// <returns>List of changed boards</returns>
    [HttpGet("boards")]
    public async Task<ActionResult<IEnumerable<FileChangeDTO>>> GetChangedBoards([FromQuery] DateTime since)
    {
        Console.WriteLine($"[SYNC-API] GetChangedBoards called with since: {since:O}");
        
        var userId = User.FindFirst("id")?.Value;
        Console.WriteLine($"[SYNC-API] User ID: {userId}");
        
        if (string.IsNullOrEmpty(userId))
        {
            Console.WriteLine("[SYNC-API] ERROR: No user ID, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        Console.WriteLine($"[SYNC-API] Querying boards for user {userId} modified after {since:O}");
        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .OrderByDescending(b => b.ModifiedDate)
            .ToListAsync();
        Console.WriteLine($"[SYNC-API] Found {boards.Count} changed boards");

        var changes = boards.Select(b => new FileChangeDTO
        {
            FileId = b.Id,
            FileName = b.Name,
            FileType = "board",
            ModifiedDate = b.ModifiedDate
        }).ToList();

        foreach (var change in changes)
        {
            Console.WriteLine($"[SYNC-API]   - {change.FileName} ({change.FileId}), modified: {change.ModifiedDate:O}");
        }

        Console.WriteLine($"[SYNC-API] Returning {changes.Count} changed boards");
        return Ok(changes);
    }

    /// <summary>
    /// Get a summary count of changes since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string</param>
    /// <returns>Summary of change counts</returns>
    [HttpGet("summary")]
    public async Task<ActionResult<SyncSummaryDTO>> GetChangeSummary([FromQuery] DateTime since)
    {
        Console.WriteLine($"[SYNC-API] GetChangeSummary called with since: {since:O}");
        
        var userId = User.FindFirst("id")?.Value;
        Console.WriteLine($"[SYNC-API] User ID: {userId}");
        
        if (string.IsNullOrEmpty(userId))
        {
            Console.WriteLine("[SYNC-API] ERROR: No user ID, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        Console.WriteLine($"[SYNC-API] Counting artefacts for user {userId} modified after {since:O}");
        var artefactCount = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .CountAsync();
        Console.WriteLine($"[SYNC-API] Artefact count: {artefactCount}");

        Console.WriteLine($"[SYNC-API] Counting boards for user {userId} modified after {since:O}");
        var boardCount = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .CountAsync();
        Console.WriteLine($"[SYNC-API] Board count: {boardCount}");

        var summary = new SyncSummaryDTO
        {
            TotalChanges = artefactCount + boardCount,
            ArtefactChanges = artefactCount,
            BoardChanges = boardCount,
            CheckDate = DateTime.UtcNow
        };
        
        Console.WriteLine($"[SYNC-API] Returning summary - Total: {summary.TotalChanges}, Artefacts: {summary.ArtefactChanges}, Boards: {summary.BoardChanges}, Check date: {summary.CheckDate:O}");
        return Ok(summary);
    }
}
