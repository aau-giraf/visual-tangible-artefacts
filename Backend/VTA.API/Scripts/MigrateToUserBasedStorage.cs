using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.Models;

namespace VTA.API.Scripts;

/// <summary>
/// Migration script to reorganize files from flat structure to user-based structure
/// Old structure: Assets/{type}/{filename}
/// New structure: Assets/{type}/{userId}/{filename}
/// </summary>
public class MigrateToUserBasedStorage
{
    private readonly VTAContext _context;
    private readonly string _assetsPath;
    private int _movedFiles = 0;
    private int _skippedFiles = 0;
    private int _errorFiles = 0;

    public MigrateToUserBasedStorage(VTAContext context)
    {
        _context = context;
        _assetsPath = Path.Combine(Directory.GetCurrentDirectory(), "Assets");
    }

    public async Task<MigrationResult> MigrateAsync(bool dryRun = false)
    {
        Console.WriteLine($"=== File Storage Migration ===");
        Console.WriteLine($"Mode: {(dryRun ? "DRY RUN (no changes will be made)" : "LIVE MIGRATION")}");
        Console.WriteLine($"Assets Path: {_assetsPath}");
        Console.WriteLine();

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

            Console.WriteLine();
            Console.WriteLine("=== Migration Summary ===");
            Console.WriteLine($"Files moved: {_movedFiles}");
            Console.WriteLine($"Files skipped: {_skippedFiles}");
            Console.WriteLine($"Errors: {_errorFiles}");

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
            Console.WriteLine($"FATAL ERROR: {ex.Message}");
            Console.WriteLine(ex.StackTrace);
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
        Console.WriteLine("--- Migrating Artefacts ---");

        var artefacts = await _context.Artefacts.ToListAsync();
        Console.WriteLine($"Found {artefacts.Count} artefacts to process");

        foreach (var artefact in artefacts)
        {
            // Migrate image
            if (!string.IsNullOrEmpty(artefact.ImagePath))
            {
                var newImagePath = MigrateFile(
                    artefact.ImagePath,
                    "Artefacts",
                    artefact.UserId,
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
                    artefact.UserId,
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
            Console.WriteLine("Database updated with new paths");
        }
    }

    private async Task MigrateCategoriesAsync(bool dryRun)
    {
        Console.WriteLine();
        Console.WriteLine("--- Migrating Categories ---");

        var categories = await _context.Categories.ToListAsync();
        Console.WriteLine($"Found {categories.Count} categories to process");

        foreach (var category in categories)
        {
            if (!string.IsNullOrEmpty(category.ImagePath))
            {
                var newImagePath = MigrateFile(
                    category.ImagePath,
                    "Categories",
                    category.UserId,
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
            Console.WriteLine("Database updated with new paths");
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
                    Console.WriteLine($"[SKIP] {type}/{filename} - Already migrated");
                    _skippedFiles++;
                    return $"/api/Assets/{type}/{userId}/{filename}";
                }

                Console.WriteLine($"[WARN] {type}/{filename} - File not found at old location");
                _skippedFiles++;
                return null;
            }

            // Check if target already exists
            if (File.Exists(newPath))
            {
                Console.WriteLine($"[SKIP] {type}/{filename} - Already exists at new location");
                _skippedFiles++;
                return $"/api/Assets/{type}/{userId}/{filename}";
            }

            if (dryRun)
            {
                Console.WriteLine($"[DRY RUN] Would move: {type}/{filename} -> {type}/{userId}/{filename}");
                _movedFiles++;
                return $"/api/Assets/{type}/{userId}/{filename}";
            }

            // Create user directory if it doesn't exist
            if (!Directory.Exists(newDirectory))
            {
                Directory.CreateDirectory(newDirectory);
                Console.WriteLine($"[INFO] Created directory: {type}/{userId}/");
            }

            // Move the file
            File.Move(oldPath, newPath);
            Console.WriteLine($"[OK] Moved: {type}/{filename} -> {type}/{userId}/{filename}");
            _movedFiles++;

            // Return new API path
            return $"/api/Assets/{type}/{userId}/{filename}";
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ERROR] Failed to migrate {apiPath}: {ex.Message}");
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
