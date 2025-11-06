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

    /// <summary>
    /// Add Width and Height columns to savedArtefact table
    /// </summary>
    /// <returns>Migration results</returns>
    [HttpPost("add-board-size-columns")]
    public async Task<ActionResult> AddBoardSizeColumns()
    {
        try
        {
            // Use FormattableString to execute raw SQL safely
            FormattableString widthQuery = $@"
                SELECT COUNT(*) 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'savedArtefact' 
                AND COLUMN_NAME = 'width'";

            var widthExists = await _context.Database.SqlQuery<int>(widthQuery).FirstOrDefaultAsync();

            if (widthExists == 0)
            {
                await _context.Database.ExecuteSqlAsync($"ALTER TABLE savedArtefact ADD COLUMN width FLOAT NOT NULL DEFAULT 200 AFTER posY");
            }

            FormattableString heightQuery = $@"
                SELECT COUNT(*) 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'savedArtefact' 
                AND COLUMN_NAME = 'height'";

            var heightExists = await _context.Database.SqlQuery<int>(heightQuery).FirstOrDefaultAsync();

            if (heightExists == 0)
            {
                await _context.Database.ExecuteSqlAsync($"ALTER TABLE savedArtefact ADD COLUMN height FLOAT NOT NULL DEFAULT 200 AFTER width");
            }

            return Ok(new
            {
                success = true,
                message = "Board size columns migration completed",
                widthAdded = widthExists == 0,
                heightAdded = heightExists == 0
            });
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
}
