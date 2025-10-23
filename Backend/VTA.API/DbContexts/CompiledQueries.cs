using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Models.Artefacts;
using VTA.API.Models.Categories;

namespace VTA.API.DbContexts;

/// <summary>
/// Contains compiled LINQ queries for optimized database access with reduced overhead.
/// Compiled queries are pre-compiled and cached, avoiding the cost of query translation on each execution.
/// </summary>
public static class CompiledQueries
{
    // ==================== CATEGORY QUERIES ====================
    
    /// <summary>
    /// Gets a limited list of default categories projected to DTOs.
    /// Default categories are system-wide categories available to all users.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of default category DTOs with relative image paths</returns>
    public static Func<VTAContext, IAsyncEnumerable<CategoryGetDTO>> GetDefaultCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<DefaultCategory>()
                .Select(CategoryProjections.DefaultCategoryToDto));

    /// <summary>
    /// Gets a limited list of user-specific categories projected to DTOs.
    /// Filters categories to only those belonging to the specified user.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose categories to retrieve</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of user category DTOs with relative image paths</returns>
    public static Func<VTAContext, Guid, IAsyncEnumerable<CategoryGetDTO>> GetUserCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, Guid userId) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserCategory>()
                .Where(x => x.UserId == userId)
                .Select(CategoryProjections.UserCategoryToDto));

    /// <summary>
    /// Gets the most frequently used categories for a specific user, ordered by usage count and last used date.
    /// Useful for displaying recently/frequently accessed categories in the UI.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose categories to retrieve</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of user category DTOs ordered by usage, with relative image paths</returns>
    public static Func<VTAContext, Guid, int, IAsyncEnumerable<CategoryGetDTO>> GetMostUsedUserCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, Guid userId, int limit = 100) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserCategory>()
                .Where(x => x.UserId == userId)
                .Select(CategoryProjections.UserCategoryToDto)
                .OrderByDescending(x => x.UsageCount)
                .ThenByDescending(x => x.LastUsedDate)
                .Take(limit));

    /// <summary>
    /// Gets a single user category by its ID and user ID.
    /// Returns null if the category doesn't exist or doesn't belong to the specified user.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user who owns the category</param>
    /// <param name="categoryId">The ID of the category to retrieve</param>
    /// <returns>A task resolving to the category DTO with relative image paths, or null if not found</returns>
    public static Func<VTAContext, Guid, Guid, IAsyncEnumerable<CategoryGetDTO>> GetUserCategoryDTOById =
        EF.CompileAsyncQuery((VTAContext context, Guid userId, Guid categoryId) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserCategory>()
                .Where(x => x.UserId == userId && x.Id == categoryId)
                .Select(CategoryProjections.UserCategoryToDto));

    // ==================== ARTEFACT QUERIES ====================

    /// <summary>
    /// Gets all default artefacts projected to DTOs.
    /// Default artefacts are system-wide artefacts available to all users.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <returns>An async enumerable of default artefact DTOs with relative image and sound paths</returns>
    public static Func<VTAContext, IAsyncEnumerable<ArtefactGetDTO>> GetDefaultArtefactDTOs =
        EF.CompileAsyncQuery((VTAContext context) =>
            context.Artefacts
                .AsNoTrackingWithIdentityResolution()
                .OfType<DefaultArtefact>()
                .Select(ArtefactProjections.DefaultArtefactToDto));

    /// <summary>
    /// Gets all user-specific artefacts projected to DTOs.
    /// Filters artefacts to only those belonging to the specified user.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose artefacts to retrieve</param>
    /// <returns>An async enumerable of user artefact DTOs with relative image and sound paths</returns>
    public static Func<VTAContext, Guid, IAsyncEnumerable<ArtefactGetDTO>> GetUserArtefactDTOs =
        EF.CompileAsyncQuery((VTAContext context, Guid userId) =>
            context.Artefacts
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserArtefact>()
                .Where(x => x.UserId == userId)
                .Select(ArtefactProjections.UserArtefactToDto));

    /// <summary>
    /// Gets a single user artefact by its ID and user ID.
    /// Returns null if the artefact doesn't exist or doesn't belong to the specified user.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user who owns the artefact</param>
    /// <param name="artefactId">The ID of the artefact to retrieve</param>
    /// <returns>An async enumerable containing the artefact DTO with relative image and sound paths, or empty if not found</returns>
    public static Func<VTAContext, Guid, Guid, IAsyncEnumerable<ArtefactGetDTO>> GetUserArtefactDTOById =
        EF.CompileAsyncQuery((VTAContext context, Guid userId, Guid artefactId) =>
            context.Artefacts
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserArtefact>()
                .Where(x => x.UserId == userId && x.Id == artefactId)
                .Select(ArtefactProjections.UserArtefactToDto));
}