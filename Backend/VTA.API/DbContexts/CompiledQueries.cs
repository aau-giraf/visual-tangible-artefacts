using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.DbContexts;

/// <summary>
/// Contains compiled LINQ queries for optimized database access with reduced overhead.
/// Compiled queries are pre-compiled and cached, avoiding the cost of query translation on each execution.
/// </summary>
public static class CompiledQueries
{
    /// <summary>
    /// Gets a limited list of default categories projected to DTOs.
    /// Default categories are system-wide categories available to all users.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of default category DTOs with relative image paths</returns>
    public static Func<VTAContext, int, IAsyncEnumerable<CategoryGetDTO>> GetDefaultCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, int limit = 100) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<DefaultCategory>()
                .Select(CategoryProjections.DefaultCategoryToDto)
                .Take(limit));

    /// <summary>
    /// Gets a limited list of user-specific categories projected to DTOs.
    /// Filters categories to only those belonging to the specified user.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose categories to retrieve</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of user category DTOs with relative image paths</returns>
    public static Func<VTAContext, string, int, IAsyncEnumerable<CategoryGetDTO>> GetUserCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, string userId, int limit = 100) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserCategory>()
                .Where(x => x.UserId == userId)
                .Select(CategoryProjections.UserCategoryToDto)
                .Take(limit));

    /// <summary>
    /// Gets the most frequently used categories for a specific user, ordered by usage count and last used date.
    /// Useful for displaying recently/frequently accessed categories in the UI.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose categories to retrieve</param>
    /// <param name="limit">Maximum number of categories to return (default: 100)</param>
    /// <returns>An async enumerable of user category DTOs ordered by usage, with relative image paths</returns>
    public static Func<VTAContext, string, int, IAsyncEnumerable<CategoryGetDTO>> GetMostUsedUserCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, string userId, int limit = 100) =>
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
    public static Func<VTAContext, string, string, Task<CategoryGetDTO?>> GetUserCategoryDTOById =
        EF.CompileAsyncQuery((VTAContext context, string userId, string categoryId) =>
            (CategoryGetDTO?)context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<UserCategory>()
                .Where(x => x.UserId == userId && x.CategoryId == categoryId)
                .Select(CategoryProjections.UserCategoryToDto)
                .FirstOrDefault());

    /// <summary>
    /// Gets all categories accessible to a user by combining default categories and user-specific categories.
    /// This provides a complete view of all categories a user can work with.
    /// </summary>
    /// <param name="context">The database context</param>
    /// <param name="userId">The ID of the user whose categories to retrieve</param>
    /// <returns>An async enumerable of all category DTOs (default + user-specific) with relative image paths</returns>
    public static Func<VTAContext, string, IAsyncEnumerable<CategoryGetDTO>> GetAllCategoryDTOs =
        EF.CompileAsyncQuery((VTAContext context, string userId) =>
            context.Categories
                .AsNoTrackingWithIdentityResolution()
                .OfType<DefaultCategory>()
                .Select(CategoryProjections.DefaultCategoryToDto)
                .Union(
                    context.Categories
                        .AsNoTrackingWithIdentityResolution()
                        .OfType<UserCategory>()
                        .Where(x => x.UserId == userId)
                        .Select(CategoryProjections.UserCategoryToDto)));
}