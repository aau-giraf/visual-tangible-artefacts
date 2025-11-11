using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.Scripts;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for running data migrations
/// WARNING: This should be protected or removed in production
/// </summary>
[Authorize]
[Route("api/Migration")]
[ApiController]
public class MigrationController : ControllerBase
{
    private readonly VTAContext _context;

    public MigrationController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Migrates files from flat structure to user-based structure
    /// </summary>
    /// <param name="dryRun">If true, simulates the migration without making changes</param>
    /// <returns>Migration results</returns>
    [HttpPost("migrate-to-user-based-storage")]
    public async Task<ActionResult<MigrationResult>> MigrateToUserBasedStorage([FromQuery] bool dryRun = true)
    {
        try
        {
            var migration = new MigrateToUserBasedStorage(_context);
            var result = await migration.MigrateAsync(dryRun);

            if (result.Success)
            {
                return Ok(result);
            }
            else
            {
                return StatusCode(500, result);
            }
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                success = false,
                errorMessage = ex.Message
            });
        }
    }

    // Note: Board layout migration endpoints removed - use mysql_schema.sql for fresh deployments
}
