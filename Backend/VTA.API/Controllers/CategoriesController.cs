using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.Controllers
{
    [Authorize]
    [Route("api/Users/Categories")]
    [ApiController]
    public class CategoriesController : ControllerBase
    {
        private readonly CategoryContext _context;

        public CategoriesController(CategoryContext context)
        {
            _context = context;
        }

        // GET: api/Categories
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

        // PUT: api/Categories/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{categoryId}")]
        public async Task<IActionResult> PutCategory(string categoryId, Category category)
        {
            var userId = User.FindFirst("id")?.Value;

            if (userId != category.UserId)
            {
                return Forbid();
            }
            if (categoryId != category.CategoryId)
            {
                return BadRequest();
            }

            _context.Entry(category).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!CategoryExists(categoryId))
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
        [HttpPost]
        public async Task<ActionResult<Category>> PostCategory(CategoryPostDTO categoryPostDTO)
        {
            var userId = User.FindFirst("id")?.Value;

            if (userId != categoryPostDTO.UserId)
            {
                return Forbid();
            }
            Category category = DTOConverter.MapCategoryPostDTOToCategory(categoryPostDTO, Guid.NewGuid().ToString());

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
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetCategory", new { categoryId = category.CategoryId }, category);
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

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool CategoryExists(string id)
        {
            return _context.Categories.Any(e => e.CategoryId == id);
        }
    }
}
