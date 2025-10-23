using System.Linq.Expressions;
using VTA.API.Models;
using VTA.API.Models.Artefacts;

namespace VTA.API.DTOs;

/// <summary>
/// Contains expression-based projections for mapping artefact entities to DTOs.
/// These projections can be used in EF Core LINQ queries and will be translated to SQL for optimal performance.
/// </summary>
public static class ArtefactProjections
{
    /// <summary>
    /// Projects an UserArtefact entity to an ArtefactGetDTO.
    /// Returns relative image and sound paths that need to be converted to full URLs using WithFullUrls() extension method.
    /// </summary>
    /// <remarks>
    /// This projection is translatable to SQL and can be used in EF Core queries for optimal performance.
    /// Both ImageUrl and SoundUrl will contain relative paths (e.g., "/api/Assets/Artefacts/guid.png").
    /// </remarks>
    public static Expression<Func<UserArtefact, ArtefactGetDTO>> UserArtefactToDto =>
        a => new ArtefactGetDTO
        {
            ArtefactId = a.Id,
            ArtefactIndex = a.ArtefactIndex,
            UserId = a.UserId,
            CategoryId = a.CategoryId,
            Name = a.Name,
            ImageUrl = a.ImagePath,
            SoundUrl = a.SoundPath
        };

    /// <summary>
    /// Projects an DefaultArtefact entity to an ArtefactGetDTO.
    /// Returns relative image and sound paths that need to be converted to full URLs using WithFullUrls() extension method.
    /// </summary>
    /// <remarks>
    /// This projection is translatable to SQL and can be used in EF Core queries for optimal performance.
    /// Both ImageUrl and SoundUrl will contain relative paths (e.g., "/api/Assets/Artefacts/guid.png").
    /// </remarks>
    public static Expression<Func<DefaultArtefact, ArtefactGetDTO>> DefaultArtefactToDto =>
        a => new ArtefactGetDTO
        {
            ArtefactId = a.Id,
            ArtefactIndex = a.ArtefactIndex,
            CategoryId = a.CategoryId,
            Name = a.Name,
            ImageUrl = a.ImagePath,
            SoundUrl = a.SoundPath
        };
    
    /// <summary>
    /// Converts relative image and sound paths to full URLs with scheme and host.
    /// Mutates the DTO in place for optimal performance.
    /// </summary>
    /// <param name="dto">The artefact DTO to transform</param>
    /// <param name="scheme">The URL scheme (e.g., "http" or "https")</param>
    /// <param name="host">The host name and optional port (e.g., "130.225.39.203:5192")</param>
    /// <returns>The same DTO instance with full URLs applied (supports fluent chaining)</returns>
    /// <remarks>
    /// This method modifies the DTO in place rather than creating a new instance for better memory efficiency.
    /// Transforms both image and sound URLs if they are present.
    /// </remarks>
    public static ArtefactGetDTO WithFullUrls(this ArtefactGetDTO dto, string scheme, string host)
    {
        var baseUrl = $"{scheme}://{host}";

        if (dto.ImageUrl != null)
        {
            dto.ImageUrl = baseUrl + dto.ImageUrl;
        }

        if (dto.SoundUrl != null)
        {
            dto.SoundUrl = baseUrl + dto.SoundUrl;
        }

        return dto;
    }

    /// <summary>
    /// Converts relative image and sound paths to full URLs using a pre-constructed base URL.
    /// Mutates the DTO in place for optimal performance.
    /// </summary>
    /// <param name="dto">The artefact DTO to transform</param>
    /// <param name="baseUrl">The pre-constructed base URL including scheme and host (e.g., "http://130.225.39.203:5192")</param>
    /// <returns>The same DTO instance with full URLs applied (supports fluent chaining)</returns>
    /// <remarks>
    /// This overload is useful when processing multiple artefacts to avoid repeatedly constructing the base URL.
    /// Used internally by CategoryProjections.WithFullUrls() for efficiency.
    /// </remarks>
    public static ArtefactGetDTO WithFullUrls(this ArtefactGetDTO dto, string baseUrl)
    {
        if (dto.ImageUrl != null)
        {
            dto.ImageUrl = baseUrl + dto.ImageUrl;
        }

        if (dto.SoundUrl != null)
        {
            dto.SoundUrl = baseUrl + dto.SoundUrl;
        }

        return dto;
    }
}