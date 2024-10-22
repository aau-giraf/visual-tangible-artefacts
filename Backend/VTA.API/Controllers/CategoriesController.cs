using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.Models;
using VTA.API.DTOs;

namespace VTA.API.Controllers
{
    [Route("api/{userID}/Users/Categories")]
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
        public async Task<ActionResult<IEnumerable<CategoryGetDTO>>> GetCategories(string userID)
        {
            List<Category> categories = await _context.Categories.Where(c => c.UserId == userID).ToListAsync();
            List<CategoryGetDTO> categoryGetDTOs = new List<CategoryGetDTO>();
            foreach (Category category in categories)
            {
                categoryGetDTOs.Add(DTOConverter.MapCategoryToCategoryGetDTO(category));
            }
            return categoryGetDTOs;
        }

        // GET: api/Categories/5
        [HttpGet("{categoryId}")]
        public async Task<ActionResult<CategoryGetDTO>> GetCategory(string userID, string categoryId)
        {
            var categories = await _context.Categories.Where(c => c.CategoryId == categoryId).ToListAsync();
            var category = categories.First();

            if (category == null)
            {
                return NotFound();
            }

            CategoryGetDTO categoryGetDTO = DTOConverter.MapCategoryToCategoryGetDTO(category);

            return categoryGetDTO;
        }

        // PUT: api/Categories/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{categoryId}")]
        public async Task<IActionResult> PutCategory(string userID, string categoryId, Category category)
        {
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
        public async Task<ActionResult<Category>> PostCategory(string userID, CategoryPostDTO categoryPostDTO)
        {
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
        public async Task<IActionResult> DeleteCategory(string userID, string categoryId)
        {
            var category = await _context.Categories.FindAsync(categoryId);
            if (category == null)
            {
                return NotFound();
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
