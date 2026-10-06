using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;

namespace VTA.API.Extensions;


// Reusable IQueryable extension for applying skip/take pagination
// and materializing the result into a <see cref="PaginatedResponse{T}"/>.
public static class PaginationExtensions
{
   
    // Default page size when no take value is specified or take is &lt;= 0.
    public const int DefaultPageSize = 50;

    // Maximum allowed page size to prevent abuse.
    public const int MaxPageSize = 200;

    // Applies skip/take pagination to an IQueryable{T},
    // counts the total matching rows, and returns a paginated response.
    // query = The source query (ordering should already be applied).
    // skip = Number of items to skip (default 0).
    // take = Number of items to take
        public static async Task<PaginatedResponse<T>> ToPaginatedAsync<T>(
        this IQueryable<T> query,
        int? skip = null,
        int? take = null)
    {
        var resolvedSkip = Math.Max(skip ?? 0, 0);
        //If take is null choose default page size, then limits it to between 1 and maximum page size.
        var resolvedTake = Math.Clamp(take ?? DefaultPageSize, 1, MaxPageSize); 

        var totalCount = await query.CountAsync();

        var items = await query
            .Skip(resolvedSkip)
            .Take(resolvedTake)
            .ToListAsync();

        //Returns a paginated response with items, total count, and pagination metadata.
        return new PaginatedResponse<T>
        {
            Items = items,
            TotalCount = totalCount,
            Skip = resolvedSkip,
            Take = resolvedTake
        };
    }
}
