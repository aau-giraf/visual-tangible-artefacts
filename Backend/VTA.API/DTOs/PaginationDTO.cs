namespace VTA.API.DTOs;

/// <summary>
/// Generic wrapper for paginated list responses.
/// All list endpoints return this shape when <c>skip</c>/<c>take</c> are supplied.
/// Backward-compatible: when no pagination params are given, <c>Items</c>
/// contains the full result set and <c>TotalCount</c> equals <c>Items.Count</c>.
/// </summary>
public class PaginatedResponse<T>
{
    /// <summary>The page of results.</summary>
    public required List<T> Items { get; set; }

    /// <summary>Total number of items matching the query (before skip/take).</summary>
    public int TotalCount { get; set; }

    /// <summary>Number of items skipped (0-based offset).</summary>
    public int Skip { get; set; }

    /// <summary>Maximum items returned in this page.</summary>
    public int Take { get; set; }
}
