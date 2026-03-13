using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UserSettingsController : ControllerBase
{
    private readonly VTAContext _context;

    public UserSettingsController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get the current user's VTA-specific settings. Auto-creates defaults on first access.
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<UserSettings>> GetSettings()
    {
        var userId = GetUserId();
        if (userId is null)
            return Unauthorized();

        var settings = await GetOrCreateSettingsAsync(userId.Value);
        return Ok(settings);
    }

    /// <summary>
    /// Update the current user's VTA-specific settings.
    /// </summary>
    [HttpPatch]
    public async Task<ActionResult<UserSettings>> UpdateSettings([FromBody] UserSettingsPatchDTO dto)
    {
        var userId = GetUserId();
        if (userId is null)
            return Unauthorized();

        var settings = await GetOrCreateSettingsAsync(userId.Value);

        if (dto.NameVisible.HasValue)
            settings.NameVisible = dto.NameVisible.Value;

        if (dto.FieldCount.HasValue)
            settings.FieldCount = dto.FieldCount.Value;

        await _context.SaveChangesAsync();
        return Ok(settings);
    }

    private int? GetUserId()
    {
        var sub = User.FindFirst("sub")?.Value;
        return int.TryParse(sub, out var id) ? id : null;
    }

    private async Task<UserSettings> GetOrCreateSettingsAsync(int userId)
    {
        var settings = await _context.UserSettings.FindAsync(userId);
        if (settings is not null)
            return settings;

        settings = new UserSettings { UserId = userId };
        _context.UserSettings.Add(settings);
        await _context.SaveChangesAsync();
        return settings;
    }
}

/// <summary>
/// DTO for patching user settings
/// </summary>
public class UserSettingsPatchDTO
{
    public bool? NameVisible { get; set; }
    public int? FieldCount { get; set; }
}
