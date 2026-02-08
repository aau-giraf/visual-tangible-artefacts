using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;

namespace VTA.API.Extensions;

/// <summary>
/// Reusable IQueryable extension for applying skip/take pagination
/// and materializing the result into a <see cref="PaginatedResponse{T}"/>.
/// </summary>
public static class PaginationExtensions
{
    /// <summary>
    /// Default page size when no take value is specified or take is &lt;= 0.
    /// </summary>
    public const int DefaultPageSize = 50;

    /// <summary>
    /// Maximum allowed page size to prevent abuse.
    /// </summary>
    public const int MaxPageSize = 200;

    /// <summary>
    /// Applies skip/take pagination to an <see cref="IQueryable{T}"/>,
    /// counts the total matching rows, and returns a <see cref="PaginatedResponse{T}"/>.
    /// </summary>
    /// <param name="query">The source query (ordering should already be applied).</param>
    /// <param name="skip">Number of items to skip (default 0).</param>
    /// <param name="take">Number of items to take (default <see cref="DefaultPageSize"/>, max <see cref="MaxPageSize"/>).</param>
    /// <returns>A paginated response with items, total count, and pagination metadata.</returns>
    public static async Task<PaginatedResponse<T>> ToPaginatedAsync<T>(
        this IQueryable<T> query,
        int? skip = null,
        int? take = null)
    {
        var resolvedSkip = Math.Max(skip ?? 0, 0);
        var resolvedTake = Math.Clamp(take ?? DefaultPageSize, 1, MaxPageSize);

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip(resolvedSkip)
            .Take(resolvedTake)
            .ToListAsync();

        return new PaginatedResponse<T>
        {
            Items = items,
            TotalCount = totalCount,
            Skip = resolvedSkip,
            Take = resolvedTake
        };
    }
}
