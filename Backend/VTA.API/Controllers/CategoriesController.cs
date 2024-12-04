using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Users/Categories")]//We designed the route so that *Users* OWNS *Categories* and this route reflects it
[ApiController]
public class CategoriesController : ControllerBase
{
    private readonly CategoryContext _context;

    public CategoriesController(CategoryContext context)
    {
        _context = context;
    }

    // GET: api/Categories
    /// <summary>
    /// Gets all categories (and artefacts within them) that a user owns
    /// </summary>
    /// <returns>An IEnumerable of Categories</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CategoryGetDTO>>> GetCategories()
    {
        var userId = User.FindFirst("id")?.Value;

        List<Category> categories = await _context.Categories.Where(c => c.UserId == userId).Include(c => c.Artefacts).ToListAsync();
        List<CategoryGetDTO> categoryGetDTOs = new List<CategoryGetDTO>();
        foreach (Category category in categories)
        {
            categoryGetDTOs.Add(DTOConverter.MapCategoryToCategoryGetDTO(category, Request.Scheme, Request.Host.ToString()));
        }

        return categoryGetDTOs;
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
        var userId = User.FindFirst("id")?.Value;

        var categories = await _context.Categories.Where(c => c.CategoryId == categoryId).Where(c => c.UserId == userId).Include(c => c.Artefacts).ToListAsync();
        var category = categories.First();

        if (category == null)
        {
            return NotFound();
        }

        CategoryGetDTO categoryGetDTO = DTOConverter.MapCategoryToCategoryGetDTO(category, Request.Scheme, Request.Host.ToString());

        return categoryGetDTO;
    }

    // PATCH: api/Categories/5
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Patches a category (there is a nuget package to do this, I, however find it... weird, so I haven't used it yet :( )
    /// </summary>
    /// <param name="dto">A category with the fields that should be altered</param>
    /// <returns>Status code 204 (No content) to the client on success</returns>
    [HttpPatch]
    public async Task<IActionResult> PatchCategory([FromForm] CategoryPatchDTO dto)
    {
        var userId = User.FindFirst("id")?.Value;

        var category = _context.Categories.Find(dto.CategoryId);

        if (category == null)
        {
            return BadRequest();
        }
        //If the index is not null, and not the same as the existing one, update it
        if (dto.CategoryIndex != null && category.CategoryIndex != dto.CategoryIndex)
        {
            category.CategoryIndex = dto.CategoryIndex;
        }
        //If the name is not null, or empty, and not the same as the existing name, updat eit
        if (!dto.Name.IsNullOrEmpty() && category.Name != dto.Name)
        {
            category.Name = dto.Name;
        }
        //if the image is not null, replace it. (I considered creating/adding an algorithm that checks if it's the same image, but i chose not to bother (it should be simple enough though))
        if (dto.Image != null)
        {
            ImageUtilities.DeleteImage(category.CategoryId, "Categories");
            ImageUtilities.AddImage(dto.Image, dto.CategoryId, "Categories");
        }

        _context.Entry(category).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!CategoryExists(category.CategoryId))
            {
                return NotFound();
            }
            else
            {
                throw;
            }
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
    /// Status code 200 (Ok) to the client on success (Ok should also have the item with it)<br />
    /// Status code 403 (Forbidden) if a client tries to add an artefact to someone else<br />
    /// </returns>
    [RequestSizeLimit(20000000)]//20mb (Greater than an 8K image) 
    [HttpPost]
    public async Task<ActionResult<CategoryGetDTO>> PostCategory([FromForm] CategoryPostDTO categoryPostDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (userId != categoryPostDTO.UserId)
        {
            return Forbid();
        }

        string id = Guid.NewGuid().ToString();
        string? imageUrl = ImageUtilities.AddImage(categoryPostDTO.Image, id, "Categories");

        Category category = DTOConverter.MapCategoryPostDTOToCategory(categoryPostDTO, id, imageUrl);

        _context.Categories.Add(category);
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            Console.WriteLine(ex.ToString());
            if (CategoryExists(category.CategoryId))
            {
                //Chance of this happening is infinitely small ! But never zero !
                while (CategoryExists(category.CategoryId))
                {
                    category.CategoryId = Guid.NewGuid().ToString();
                }
                await _context.SaveChangesAsync();
            }
            else
            {
                throw;
            }
        }
        var cat = await _context.Categories.FindAsync(id);

        CategoryGetDTO returnCat = DTOConverter.MapCategoryToCategoryGetDTO(cat, Request.Scheme, Request.Host.ToString());

        return Ok(returnCat);
    }

    // DELETE: api/Categories/5
    [HttpDelete("{categoryId}")]
    public async Task<IActionResult> DeleteCategory(string categoryId)
    {
        var userId = User.FindFirst("id")?.Value;

        var category = await _context.Categories.FindAsync(categoryId);

        if (category == null)
        {
            return NotFound();
        }
        if (userId != category.UserId)
        {
            return Forbid();
        }
        foreach (var artefact in category.Artefacts)
        {
            ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts");
        }

        ImageUtilities.DeleteImage(category.CategoryId, "Categories");

        _context.Categories.Remove(category);//MySQL is set to cascade delete, so upon calling SaveChangesAsync, the database automagically deletes all artefacts in this cat
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool CategoryExists(string id)
    {
        return _context.Categories.Any(e => e.CategoryId == id);
    }
}