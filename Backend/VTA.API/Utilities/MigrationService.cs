using Microsoft.EntityFrameworkCore;
using VTA.Data.DbContexts;

namespace VTA.API.Utilities;

/// <summary>
/// Migration script to reorganize files from flat structure to user-based structure
/// Old structure: Assets/{type}/{filename}
/// New structure: Assets/{type}/{userId}/{filename}
/// </summary>
public class MigrationService
{
    private readonly VTAContext _context;
    private readonly ILogger<MigrationService> _logger;
    private readonly string _assetsPath;
    private int _movedFiles = 0;
    private int _skippedFiles = 0;
    private int _errorFiles = 0;

    public MigrationService(VTAContext context, ILogger<MigrationService> logger)
    {
        _context = context;
        _logger = logger;
        _assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets");
    }

    public async Task<MigrationResult> MigrateAsync(bool dryRun = false)
    {
        _logger.LogInformation("=== File Storage Migration ===");
        _logger.LogInformation("Mode: {Mode}", dryRun ? "DRY RUN (no changes will be made)" : "LIVE MIGRATION");
        _logger.LogInformation("Assets Path: {AssetsPath}", _assetsPath);

        // Reset counters
        _movedFiles = 0;
        _skippedFiles = 0;
        _errorFiles = 0;

        try
        {
            // Migrate artefact images and sounds
            await MigrateArtefactsAsync(dryRun);

            // Migrate category images
            await MigrateCategoriesAsync(dryRun);

            _logger.LogInformation("=== Migration Summary === Files moved: {Moved}, Files skipped: {Skipped}, Errors: {Errors}",
                _movedFiles, _skippedFiles, _errorFiles);

            return new MigrationResult
            {
                Success = _errorFiles == 0,
                FilesMovedCount = _movedFiles,
                FilesSkippedCount = _skippedFiles,
                ErrorsCount = _errorFiles
            };
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Fatal error during file storage migration");
            return new MigrationResult
            {
                Success = false,
                FilesMovedCount = _movedFiles,
                FilesSkippedCount = _skippedFiles,
                ErrorsCount = _errorFiles + 1,
                ErrorMessage = ex.Message
            };
        }
    }

    private async Task MigrateArtefactsAsync(bool dryRun)
    {
        _logger.LogInformation("--- Migrating Artefacts ---");

        var artefacts = await _context.Artefacts.ToListAsync();
        _logger.LogInformation("Found {Count} artefacts to process", artefacts.Count);

        foreach (var artefact in artefacts)
        {
            // Migrate image
            if (!string.IsNullOrEmpty(artefact.ImagePath))
            {
                var newImagePath = MigrateFile(
                    artefact.ImagePath,
                    "Artefacts",
                    artefact.UserId.ToString(),
                    artefact.ArtefactId,
                    dryRun
                );

                if (newImagePath != null && !dryRun)
                {
                    artefact.ImagePath = newImagePath;
                }
            }

            // Migrate sound
            if (!string.IsNullOrEmpty(artefact.SoundPath))
            {
                var newSoundPath = MigrateFile(
                    artefact.SoundPath,
                    "Sounds",
                    artefact.UserId.ToString(),
                    artefact.ArtefactId,
                    dryRun
                );

                if (newSoundPath != null && !dryRun)
                {
                    artefact.SoundPath = newSoundPath;
                }
            }
        }

        if (!dryRun && _movedFiles > 0)
        {
            await _context.SaveChangesAsync();
            _logger.LogInformation("Database updated with new artefact paths");
        }
    }

    private async Task MigrateCategoriesAsync(bool dryRun)
    {
        _logger.LogInformation("--- Migrating Categories ---");

        var categories = await _context.Categories.ToListAsync();
        _logger.LogInformation("Found {Count} categories to process", categories.Count);

        foreach (var category in categories)
        {
            if (!string.IsNullOrEmpty(category.ImagePath))
            {
                var newImagePath = MigrateFile(
                    category.ImagePath,
                    "Categories",
                    category.UserId.ToString(),
                    category.CategoryId,
                    dryRun
                );

                if (newImagePath != null && !dryRun)
                {
                    category.ImagePath = newImagePath;
                }
            }
        }

        if (!dryRun && _movedFiles > 0)
        {
            await _context.SaveChangesAsync();
            _logger.LogInformation("Database updated with new category paths");
        }
    }

    private string? MigrateFile(string apiPath, string type, string userId, string entityId, bool dryRun)
    {
        try
        {
            // Parse the API path: /api/Assets/{type}/{filename}
            var filename = Path.GetFileName(apiPath);

            // Old file location: Assets/{type}/{filename}
            var oldPath = Path.Combine(_assetsPath, type, filename);

            // New file location: Assets/{type}/{userId}/{filename}
            var newDirectory = Path.Combine(_assetsPath, type, userId);
            var newPath = Path.Combine(newDirectory, filename);

            // Check if file exists at old location
            if (!File.Exists(oldPath))
            {
                // Check if already migrated
                if (File.Exists(newPath))
                {
                    _logger.LogDebug("[SKIP] {Type}/{Filename} - Already migrated", type, filename);
                    _skippedFiles++;
                    return $"/api/Assets/{type}/{userId}/{filename}";
                }

                _logger.LogWarning("{Type}/{Filename} - File not found at old location", type, filename);
                _skippedFiles++;
                return null;
            }

            // Check if target already exists
            if (File.Exists(newPath))
            {
                _logger.LogDebug("[SKIP] {Type}/{Filename} - Already exists at new location", type, filename);
                _skippedFiles++;
                return $"/api/Assets/{type}/{userId}/{filename}";
            }

            if (dryRun)
            {
                _logger.LogDebug("[DRY RUN] Would move: {Type}/{Filename} -> {Type}/{UserId}/{Filename2}", type, filename, type, userId, filename);
                _movedFiles++;
                return $"/api/Assets/{type}/{userId}/{filename}";
            }

            // Create user directory if it doesn't exist
            if (!Directory.Exists(newDirectory))
            {
                Directory.CreateDirectory(newDirectory);
                _logger.LogDebug("Created directory: {Type}/{UserId}/", type, userId);
            }

            // Move the file
            File.Move(oldPath, newPath);
            _logger.LogDebug("Moved: {Type}/{Filename} -> {Type}/{UserId}/{Filename2}", type, filename, type, userId, filename);
            _movedFiles++;

            // Return new API path
            return $"/api/Assets/{type}/{userId}/{filename}";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to migrate {ApiPath}", apiPath);
            _errorFiles++;
            return null;
        }
    }
}

public class MigrationResult
{
    public bool Success { get; set; }
    public int FilesMovedCount { get; set; }
    public int FilesSkippedCount { get; set; }
    public int ErrorsCount { get; set; }
    public string? ErrorMessage { get; set; }
}
