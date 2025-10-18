using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Users/Categories")]
[ApiController]
public class CategoriesController(VTAContext context) : ControllerBase
{
    // GET: api/Categories
    /// <summary>
    /// Gets all categories (and artefacts within them) that a user owns
    /// </summary>
    /// <returns>An IEnumerable of Categories</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryGetDTO>>> GetCategories()
    {
        var userId = User.FindFirst("id")?.Value!;
        
        var categories = await CompiledQueries.GetAllCategoryDTOs(context, userId)
            .ToListAsync();
        
        if (categories.Count == 0)
        {
            return NotFound();
        }
        
        var categoriesWithFullUrls = categories
            .Select(x => x.WithFullUrls(Request.Scheme, Request.Host.ToString()))
            .ToList();
        
        return categoriesWithFullUrls;
    }

    // GET: api/Categories/5
    /// <summary>
    /// Gets a specific category (and it's artefacts)
    /// </summary>
    /// <param name="categoryId">The category to get</param>
    /// <returns>The specified category</returns>
    [HttpGet("{categoryId}")]
    public async Task<ActionResult<CategoryGetDTO>> GetCategory(string categoryId)
    {
        var userId = User.FindFirst("id")?.Value!;
        
        var category = await CompiledQueries.GetUserCategoryDTOById(context, userId, categoryId);

        if (category is null)
        {
            return NotFound();
        }

        return category;
    }

    // PATCH: api/Categories/5
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Patches a category (there is a nuget package to do this, I, however find it... weird, so I haven't used it yet :( )
    /// </summary>
    /// <param name="dto">A category with the fields that should be altered</param>
    /// <returns>Status code 204 (No content) to the client on success</returns>
    [HttpPatch]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<IActionResult> PatchCategory([FromForm] CategoryPatchDTO dto)
    {
        var userId = User.FindFirst("id")?.Value!;
        
        var rowsAffected = await context.Categories
            .OfType<UserCategory>()
            .Where(c => c.CategoryId == dto.CategoryId && c.UserId == userId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(c => c.CategoryIndex, c => dto.CategoryIndex ?? c.CategoryIndex)
                .SetProperty(c => c.Name, c => dto.Name ?? c.Name));
        
        if (rowsAffected == 0)
        {
            return NotFound();
        }
        
        //if the image is not null, replace it. (I considered creating/adding an algorithm that checks if it's the same image, but i chose not to bother (it should be simple enough though))
        if (dto.Image != null)
        {
            ImageUtilities.ReplaceImage(dto.Image, dto.CategoryId, "Categories");
        }

        return NoContent();
    }

    // POST: api/Categories
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Creates a new category
    /// </summary>
    /// <param name="categoryPostDTO">An object with all category info</param>
    /// <returns>
    /// Status code 201 (Created) to the client on success with the created category<br />
    /// Status code 403 (Forbidden) if a client tries to add a category for someone else<br />
    /// </returns>
    [HttpPost]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<ActionResult<CategoryGetDTO>> PostCategory([FromForm] CategoryPostDTO categoryPostDTO)
    {
        var userId = User.FindFirst("id")?.Value!;

        if (userId != categoryPostDTO.UserId)
        {
            return Forbid();
        }

        string id = Guid.NewGuid().ToString();
        string? imageUrl = ImageUtilities.AddImage(categoryPostDTO.Image, id, "Categories");

        UserCategory category = DTOConverter.MapCategoryPostDTOToCategory(categoryPostDTO, id, imageUrl);

        context.Categories.Add(category);
        await context.SaveChangesAsync();

        var categoryGetDto = DTOConverter.MapUserCategoryToCategoryGetDTO(category, Request.Scheme, Request.Host.ToString());
        
        return CreatedAtAction("GetCategory", new { categoryId = categoryGetDto.CategoryId }, categoryGetDto);
    }

    // DELETE: api/Categories/5
    /// <summary>
    /// Deletes a user category using its ID
    /// </summary>
    /// <param name="categoryId">The category ID</param>
    /// <returns>
    /// Status code 204 (No content) to the client on success<br />
    /// Status code 403 (Forbidden) if a client tries to delete a category that they do not own<br />
    /// Status code 404 (Not Found) if the category does not exist
    /// </returns>
    [HttpDelete("{categoryId}")]
    public async Task<IActionResult> DeleteCategory(string categoryId)
    {
        var userId = User.FindFirst("id")?.Value!;

        // First, get the artefact IDs associated with the category to delete their images later
        var categoryArtefactIds = await context.Categories
            .OfType<UserCategory>()
            .Where(x => x.UserId == userId && x.CategoryId == categoryId)
            .SelectMany(x => x.Artefacts)
            .Select(x => x.ArtefactId)
            .ToListAsync();
        
        // Optimized the update to avoid loading the entire entity into memory
        var rowsAffected = await context.Categories
            .OfType<UserCategory>()
            .Where(c => c.CategoryId == categoryId && c.UserId == userId)
            .ExecuteDeleteAsync();

        if (rowsAffected == 0)
        {
            return NotFound();
        }
        
        // Now, delete the images associated with the artefacts and the category itself
        // Optimally this should be done asynchronously also to avoid having to load the categoryArtefactIds, but for simplicity, we'll do it synchronously here
        foreach (var artefactId in categoryArtefactIds)
        {
            ImageUtilities.DeleteImage(artefactId, "Artefacts");
        }

        ImageUtilities.DeleteImage(categoryId, "Categories");

        return NoContent();
    }

    // POST: api/Categories/{categoryId}/usage
    /// <summary>
    /// Tracks when a category is used by incrementing usage count and updating last used date
    /// </summary>
    /// <param name="categoryId">The category ID to track usage for</param>
    /// <returns>Status code 204 (No content) on success</returns>
    [HttpPost("{categoryId}/usage")]
    public async Task<IActionResult> TrackCategoryUsage(string categoryId)
    {
        var userId = User.FindFirst("id")?.Value;

        // Optimized the update to avoid loading the entire entity into memory
        var rowsAffected = await context.Categories
            .OfType<UserCategory>()
            .Where(c => c.CategoryId == categoryId && c.UserId == userId)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(c => c.UsageCount, c => c.UsageCount + 1)
                .SetProperty(c => c.LastUsedDate, DateTime.UtcNow));

        if (rowsAffected == 0)
        {
            return NotFound();
        }

        return NoContent();
    }

    // GET: api/Categories/most-used
    /// <summary>
    /// Gets the most used categories for the authenticated user
    /// </summary>
    /// <param name="limit">Number of most used categories to return (default: 5)</param>
    /// <returns>A list of the most used categories</returns>
    [HttpGet("most-used")]
    public async Task<ActionResult<IEnumerable<CategoryGetDTO>>> GetMostUsedCategories(int limit = 5)
    {
        var userId = User.FindFirst("id")?.Value!;

        // Optimized the query using compiled queries with projection instead of loading full entities and then mapping
        
        var categories = await CompiledQueries
            .GetMostUsedUserCategoryDTOs(context, userId, limit)
            .ToListAsync();
        
        if (categories.Count == 0)
        {
            return NotFound();
        }

        var categoriesWithFullUrls = categories
            .Select(x => x.WithFullUrls(Request.Scheme, Request.Host.ToString()))
            .ToList();
        
        return categoriesWithFullUrls;
    }

    private bool CategoryExists(string id)
    {
        return context.Categories.Any(e => e.CategoryId == id);
    }
}