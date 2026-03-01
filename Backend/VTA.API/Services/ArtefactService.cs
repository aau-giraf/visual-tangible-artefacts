using Microsoft.EntityFrameworkCore;
using VTA.API.Utilities;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Default implementation of <see cref="IArtefactService"/>.
/// Encapsulates artefact CRUD, image/sound file management, and bulk operations.
/// Registered as scoped in DI — controllers inject this instead of
/// performing inline DB + file-system work.
/// </summary>
public class ArtefactService : IArtefactService
{
    private readonly VTAContext _context;
    private readonly ILogger<ArtefactService> _logger;

    public ArtefactService(VTAContext context, ILogger<ArtefactService> logger)
    {
        _context = context;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<List<Artefact>> GetArtefactsForUserAsync(int userId, int? skip = null, int? take = null)
    {
        var query = _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId)
            .OrderBy(a => a.ArtefactIndex);

        if (skip.HasValue || take.HasValue)
        {
            var resolvedSkip = Math.Max(skip ?? 0, 0);
            var resolvedTake = Math.Clamp(take ?? 50, 1, 200);
            return await query.Skip(resolvedSkip).Take(resolvedTake).ToListAsync();
        }

        return await query.ToListAsync();
    }

    /// <inheritdoc />
    public async Task<Artefact?> GetArtefactByIdAsync(string artefactId, int userId)
    {
        return await _context.Artefacts
            .AsNoTracking()
            .Where(a => a.UserId == userId)
            .FirstOrDefaultAsync(a => a.ArtefactId == artefactId);
    }

    /// <inheritdoc />
    public async Task<Artefact> CreateOrUpdateArtefactAsync(
        string? artefactId,
        int userId,
        string? name,
        ushort artefactIndex,
        string? categoryId,
        bool? nameShown,
        IFormFile image,
        IFormFile? sound)
    {
        Artefact? existing = null;
        string resolvedId;

        if (!string.IsNullOrEmpty(artefactId))
        {
            existing = await _context.Artefacts.FindAsync(artefactId);
            resolvedId = artefactId;
        }
        else
        {
            resolvedId = Guid.NewGuid().ToString();
        }

        var userIdStr = userId.ToString();

        // --- UPDATE path ---
        if (existing != null)
        {
            existing.Name = name;
            existing.NameShown = nameShown ?? existing.NameShown;
            existing.CategoryId = categoryId ?? existing.CategoryId;
            existing.ArtefactIndex = artefactIndex;

            // Replace image if provided
            if (image != null)
            {
                if (!string.IsNullOrEmpty(existing.ImagePath))
                {
                    ImageUtilities.DeleteImage(existing.ArtefactId, "Artefacts", userIdStr);
                }
                existing.ImagePath = await ImageUtilities.AddImage(image, resolvedId, "Artefacts", userIdStr);
            }

            // Replace sound if provided
            if (sound != null)
            {
                if (!string.IsNullOrEmpty(existing.SoundPath))
                {
                    try { SoundUtilities.DeleteSound(existing.ArtefactId, userIdStr); } catch { }
                }
                existing.SoundPath = await SoundUtilities.AddSound(sound, resolvedId, userIdStr);
            }

            _context.Entry(existing).State = EntityState.Modified;
            await _context.SaveChangesAsync();
            return existing;
        }

        // --- CREATE path ---
        var settings = await _context.UserSettings.FindAsync(userId);
        string? imagePath = await ImageUtilities.AddImage(image, resolvedId, "Artefacts", userIdStr);

        string? soundPath = null;
        if (sound != null)
        {
            soundPath = await SoundUtilities.AddSound(sound, resolvedId, userIdStr);
        }

        var artefact = new Artefact
        {
            ArtefactId = resolvedId,
            ArtefactIndex = artefactIndex,
            UserId = userId,
            CategoryId = categoryId,
            Name = name,
            NameShown = nameShown ?? settings?.NameVisible ?? false,
            ImagePath = imagePath,
            SoundPath = soundPath
        };

        _context.Artefacts.Add(artefact);

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Extremely unlikely GUID collision — retry with new ID
            if (ArtefactExists(artefact.ArtefactId))
            {
                while (ArtefactExists(artefact.ArtefactId))
                {
                    artefact.ArtefactId = Guid.NewGuid().ToString();
                }
                await _context.SaveChangesAsync();
            }
            else
            {
                throw;
            }
        }

        return artefact;
    }

    /// <inheritdoc />
    public async Task<Artefact?> PatchArtefactAsync(
        string artefactId,
        int userId,
        ushort? artefactIndex,
        string? name,
        bool? nameShown,
        IFormFile? image,
        IFormFile? sound)
    {
        var artefact = await _context.Artefacts.FindAsync(artefactId);
        if (artefact == null)
        {
            return null;
        }

        var userIdStr = userId.ToString();

        if (artefactIndex != null && artefact.ArtefactIndex != artefactIndex.Value)
        {
            artefact.ArtefactIndex = artefactIndex.Value;
        }
        if (!string.IsNullOrEmpty(name) && artefact.Name != name)
        {
            artefact.Name = name;
        }
        if (nameShown != null && artefact.NameShown != nameShown)
        {
            artefact.NameShown = nameShown;
        }

        // When the artefact has a category, updating the image also updates the
        // category image (existing behaviour carried over from the controller).
        if (image != null && !string.IsNullOrEmpty(artefact.CategoryId))
        {
            ImageUtilities.DeleteImage(artefact.CategoryId, "Categories", userIdStr);
            await ImageUtilities.AddImage(image, artefact.CategoryId, "Categories", userIdStr);
        }

        if (sound != null)
        {
            try { SoundUtilities.DeleteSound(artefact.ArtefactId, userIdStr); } catch { }
            artefact.SoundPath = await SoundUtilities.AddSound(sound, artefact.ArtefactId, userIdStr);
        }

        _context.Entry(artefact).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ArtefactExists(artefact.ArtefactId))
            {
                return null;
            }
            throw;
        }

        return artefact;
    }

    /// <inheritdoc />
    public async Task<(bool Success, string? Error)> DeleteArtefactAsync(string artefactId, int userId)
    {
        var artefact = await _context.Artefacts.FindAsync(artefactId);
        if (artefact == null)
        {
            return (false, "NotFound");
        }

        if (userId != artefact.UserId)
        {
            return (false, "Forbidden");
        }

        // Clean up files
        var userIdStr = userId.ToString();
        ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts", userIdStr);
        try { SoundUtilities.DeleteSound(artefact.ArtefactId, userIdStr); } catch { }

        _context.Artefacts.Remove(artefact);
        await _context.SaveChangesAsync();

        return (true, null);
    }

    /// <inheritdoc />
    public async Task<int> BulkUpdateNameShownAsync(int userId, bool nameShown)
    {
        var artefacts = await _context.Artefacts
            .Where(a => a.UserId == userId)
            .ToListAsync();

        foreach (var artefact in artefacts)
        {
            artefact.NameShown = nameShown;
        }

        await _context.SaveChangesAsync();
        return artefacts.Count;
    }

    /// <inheritdoc />
    public async Task<Artefact?> GetArtefactForAudioAsync(string artefactId, int userId)
    {
        return await _context.Artefacts
            .Where(a => a.UserId == userId && a.ArtefactId == artefactId)
            .FirstOrDefaultAsync();
    }

    private bool ArtefactExists(string id)
    {
        return _context.Artefacts.Any(e => e.ArtefactId == id);
    }
}
