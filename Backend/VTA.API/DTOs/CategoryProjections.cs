using System.Linq.Expressions;
using VTA.API.Models;
using VTA.API.Models.Categories;

namespace VTA.API.DTOs;

/// <summary>
/// Contains expression-based projections for mapping category entities to DTOs.
/// These projections can be used in EF Core LINQ queries and will be translated to SQL for optimal performance.
/// </summary>
public static class CategoryProjections
{
    /// <summary>
    /// Projects a UserCategory entity to a CategoryGetDTO with all related artefacts.
    /// Returns relative image paths that need to be converted to full URLs using WithFullUrls() extension method.
    /// Includes usage tracking information (UsageCount and LastUsedDate).
    /// </summary>
    /// <remarks>
    /// This projection is translatable to SQL and can be used in EF Core queries for optimal performance.
    /// The IsDefaultCategory property is set to false as this projects user-specific categories.
    /// </remarks>
    public static Expression<Func<UserCategory, CategoryGetDTO>> UserCategoryToDto =>
        c => new CategoryGetDTO
        {
            CategoryId = c.CategoryId,
            CategoryIndex = c.CategoryIndex,
            Name = c.Name,
            ImageUrl = c.ImagePath,
            UsageCount = c.UsageCount,
            LastUsedDate = c.LastUsedDate,
            Artefacts = c.Artefacts.AsQueryable().Select(ArtefactProjections.UserArtefactToDto).ToList()
        };

    /// <summary>
    /// Projects a DefaultCategory entity to a CategoryGetDTO with all related artefacts.
    /// Returns relative image paths that need to be converted to full URLs using WithFullUrls() extension method.
    /// Usage tracking fields (UsageCount and LastUsedDate) are null for default categories.
    /// </summary>
    /// <remarks>
    /// This projection is translatable to SQL and can be used in EF Core queries for optimal performance.
    /// The IsDefaultCategory property is set to true as this projects system-wide default categories.
    /// </remarks>
    public static Expression<Func<DefaultCategory, CategoryGetDTO>> DefaultCategoryToDto =>
        c => new CategoryGetDTO
        {
            CategoryId = c.CategoryId,
            CategoryIndex = c.CategoryIndex,
            Name = c.Name,
            ImageUrl = c.ImagePath,
            IsDefaultCategory = true,
            Artefacts = c.Artefacts.AsQueryable().Select(ArtefactProjections.DefaultArtefactToDto).ToList()
        };

    /// <summary>
    /// Converts relative image paths to full URLs with scheme and host.
    /// Mutates the DTO in place for optimal performance and also processes all nested artefact DTOs.
    /// </summary>
    /// <param name="dto">The category DTO to transform</param>
    /// <param name="scheme">The URL scheme (e.g., "http" or "https")</param>
    /// <param name="host">The host name and optional port (e.g., "130.225.39.203:5192")</param>
    /// <returns>The same DTO instance with full URLs applied (supports fluent chaining)</returns>
    /// <remarks>
    /// This method modifies the DTO in place rather than creating a new instance for better memory efficiency.
    /// All nested artefacts are also transformed to have full URLs.
    /// </remarks>
    public static CategoryGetDTO WithFullUrls(this CategoryGetDTO dto, string scheme, string host)
    {
        var baseUrl = $"{scheme}://{host}";

        if (dto.ImageUrl != null)
        {
            dto.ImageUrl = baseUrl + dto.ImageUrl;
        }

        foreach (var artefact in dto.Artefacts)
        {
            artefact.WithFullUrls(baseUrl);
        }

        return dto;
    }
}