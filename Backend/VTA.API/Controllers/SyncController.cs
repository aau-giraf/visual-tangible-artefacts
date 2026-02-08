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
[Route("api/Sync")]
[ApiController]
public class SyncController : ControllerBase
{
    private readonly VTAContext _context;
    private readonly ILogger<SyncController> _logger;

    /// <summary>
    /// Constructor for SyncController
    /// </summary>
    /// <param name="context">Database context</param>
    /// <param name="logger">Logger instance</param>
    public SyncController(VTAContext context, ILogger<SyncController> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <summary>
    /// Get all changes (artefacts and boards) since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string (e.g., 2024-11-27T12:00:00Z)</param>
    /// <returns>List of all changed files</returns>
    [HttpGet("changes")]
    public async Task<ActionResult<SyncResponseDTO>> GetChanges([FromQuery] DateTime since)
    {
        _logger.LogDebug("GetChanges called with since: {Since}", since);
        
        var userId = User.FindFirst("id")?.Value;
        _logger.LogDebug("User ID from token: {UserId}", userId);
        
        if (string.IsNullOrEmpty(userId))
        {
            _logger.LogWarning("No user ID in token, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        var changedFiles = new List<FileChangeDTO>();

        // Get changed artefacts
        _logger.LogDebug("Querying artefacts modified after {Since} for user {UserId}", since, userId);
        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .ToListAsync();
        _logger.LogDebug("Found {Count} changed artefacts", artefacts.Count);

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
            _logger.LogDebug("  Artefact: {Name} ({Id}), modified: {Modified}", dto.FileName, dto.FileId, dto.ModifiedDate);
        }

        // Get changed boards
        _logger.LogDebug("Querying boards modified after {Since} for user {UserId}", since, userId);
        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .ToListAsync();
        _logger.LogDebug("Found {Count} changed boards", boards.Count);

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
            _logger.LogDebug("  Board: {Name} ({Id}), modified: {Modified}", dto.FileName, dto.FileId, dto.ModifiedDate);
        }

        // Sort by modified date (most recent first)
        _logger.LogDebug("Sorting {Count} total changes by modified date", changedFiles.Count);
        changedFiles = changedFiles
            .OrderByDescending(f => f.ModifiedDate)
            .ToList();

        var response = new SyncResponseDTO
        {
            ChangedFiles = changedFiles,
            CheckDate = DateTime.UtcNow,
            TotalChanges = changedFiles.Count
        };
        
        _logger.LogInformation("GetChanges returning {TotalChanges} changes (check date: {CheckDate})", response.TotalChanges, response.CheckDate);
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
        _logger.LogDebug("GetChangedArtefacts called with since: {Since}", since);
        
        var userId = User.FindFirst("id")?.Value;
        _logger.LogDebug("User ID: {UserId}", userId);
        
        if (string.IsNullOrEmpty(userId))
        {
            _logger.LogWarning("No user ID in token, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        _logger.LogDebug("Querying artefacts for user {UserId} modified after {Since}", userId, since);
        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .OrderByDescending(a => a.ModifiedDate)
            .ToListAsync();
        _logger.LogDebug("Found {Count} changed artefacts", artefacts.Count);

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
            _logger.LogDebug("  {Name} ({Id}), modified: {Modified}", change.FileName, change.FileId, change.ModifiedDate);
        }

        _logger.LogInformation("GetChangedArtefacts returning {Count} changes", changes.Count);
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
        _logger.LogDebug("GetChangedBoards called with since: {Since}", since);
        
        var userId = User.FindFirst("id")?.Value;
        _logger.LogDebug("User ID: {UserId}", userId);
        
        if (string.IsNullOrEmpty(userId))
        {
            _logger.LogWarning("No user ID in token, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        _logger.LogDebug("Querying boards for user {UserId} modified after {Since}", userId, since);
        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .OrderByDescending(b => b.ModifiedDate)
            .ToListAsync();
        _logger.LogDebug("Found {Count} changed boards", boards.Count);

        var changes = boards.Select(b => new FileChangeDTO
        {
            FileId = b.Id,
            FileName = b.Name,
            FileType = "board",
            ModifiedDate = b.ModifiedDate
        }).ToList();

        foreach (var change in changes)
        {
            _logger.LogDebug("  {Name} ({Id}), modified: {Modified}", change.FileName, change.FileId, change.ModifiedDate);
        }

        _logger.LogInformation("GetChangedBoards returning {Count} changes", changes.Count);
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
        _logger.LogDebug("GetChangeSummary called with since: {Since}", since);
        
        var userId = User.FindFirst("id")?.Value;
        _logger.LogDebug("User ID: {UserId}", userId);
        
        if (string.IsNullOrEmpty(userId))
        {
            _logger.LogWarning("No user ID in token, returning Unauthorized");
            return Unauthorized("Invalid token");
        }

        _logger.LogDebug("Counting artefacts for user {UserId} modified after {Since}", userId, since);
        var artefactCount = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .CountAsync();
        _logger.LogDebug("Artefact count: {Count}", artefactCount);

        _logger.LogDebug("Counting boards for user {UserId} modified after {Since}", userId, since);
        var boardCount = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .CountAsync();
        _logger.LogDebug("Board count: {Count}", boardCount);

        var summary = new SyncSummaryDTO
        {
            TotalChanges = artefactCount + boardCount,
            ArtefactChanges = artefactCount,
            BoardChanges = boardCount,
            CheckDate = DateTime.UtcNow
        };
        
        _logger.LogInformation("GetChangeSummary returning Total: {Total}, Artefacts: {Artefacts}, Boards: {Boards}", summary.TotalChanges, summary.ArtefactChanges, summary.BoardChanges);
        return Ok(summary);
    }
}
