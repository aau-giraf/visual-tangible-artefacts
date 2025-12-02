using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;

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
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var changedFiles = new List<FileChangeDTO>();

        // Get changed artefacts
        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .ToListAsync();

        foreach (var artefact in artefacts)
        {
            changedFiles.Add(new FileChangeDTO
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
            });
        }

        // Get changed boards
        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .ToListAsync();

        foreach (var board in boards)
        {
            changedFiles.Add(new FileChangeDTO
            {
                FileId = board.Id,
                FileName = board.Name,
                FileType = "board",
                ModifiedDate = board.ModifiedDate
            });
        }

        // Sort by modified date (most recent first)
        changedFiles = changedFiles
            .OrderByDescending(f => f.ModifiedDate)
            .ToList();

        return Ok(new SyncResponseDTO
        {
            ChangedFiles = changedFiles,
            CheckDate = DateTime.UtcNow,
            TotalChanges = changedFiles.Count
        });
    }

    /// <summary>
    /// Get only changed artefacts since a specific date
    /// </summary>
    /// <param name="since">ISO 8601 date string</param>
    /// <returns>List of changed artefacts</returns>
    [HttpGet("artefacts")]
    public async Task<ActionResult<IEnumerable<FileChangeDTO>>> GetChangedArtefacts([FromQuery] DateTime since)
    {
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var artefacts = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .OrderByDescending(a => a.ModifiedDate)
            .ToListAsync();

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
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var boards = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .OrderByDescending(b => b.ModifiedDate)
            .ToListAsync();

        var changes = boards.Select(b => new FileChangeDTO
        {
            FileId = b.Id,
            FileName = b.Name,
            FileType = "board",
            ModifiedDate = b.ModifiedDate
        }).ToList();

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
        var userId = User.FindFirst("id")?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var artefactCount = await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId && a.ModifiedDate != null && a.ModifiedDate > since)
            .CountAsync();

        var boardCount = await _context.SavedBoards
            .AsNoTracking()
            .Where(b => b.UserId == userId && b.ModifiedDate != null && b.ModifiedDate > since)
            .CountAsync();

        return Ok(new SyncSummaryDTO
        {
            TotalChanges = artefactCount + boardCount,
            ArtefactChanges = artefactCount,
            BoardChanges = boardCount,
            CheckDate = DateTime.UtcNow
        });
    }
}
