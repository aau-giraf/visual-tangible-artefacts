using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Diagnostics;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers
{
    [Route("api/UsersController")]
    [ApiController]
    public class UsersController : ControllerBase
    {
        private readonly UserContext _context;

        public UsersController(UserContext context)
        {
            _context = context;
        }

        // GET: api/Users
        [HttpGet]
        public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetUsers()
        {
            List<User> users = await _context.Users.ToListAsync();
            List<UserGetDTO> userGetDTOs = new List<UserGetDTO>();
            foreach (User user in users)
            {
                userGetDTOs.Add(DTOConverter.MapUserToUserGetDTO(user));
            }
            return userGetDTOs;
        }

        // GET: api/Users/5
        [HttpGet("{id}")]
        public async Task<ActionResult<UserGetDTO>> GetUser(string id)
        {
            var user = await _context.Users.FindAsync(id);

            if (user == null)
            {
                return NotFound();
            }

            UserGetDTO userGetDTO = DTOConverter.MapUserToUserGetDTO(user);

            return userGetDTO;
        }

        // GET: api/Categories
        [HttpGet("{id}/categories")]
        public async Task<ActionResult<IEnumerable<CategoryGetDTO>>> GetCategories(string id)
        {
            List<Category> categories = await _context.Categories.Where(c => c.UserId == id).ToListAsync();
            List<CategoryGetDTO> categoryGetDTOs = new List<CategoryGetDTO>();
            foreach (Category category in categories)
            {
                categoryGetDTOs.Add(DTOConverter.MapCategoryToCategoryGetDTO(category));
            }
            return categoryGetDTOs;
        }

        // GET: api/Categories/5
        [HttpGet("{id}/categories/{categoryId}")]
        public async Task<ActionResult<CategoryGetDTO>> GetCategory(string id, string categoryId)
        {
            var categories = await _context.Categories.Where(c => c.CategoryId == categoryId).Where(c => c.UserId == id).ToListAsync();
            var category = categories.First();

            if (category == null)
            {
                return NotFound();
            }

            CategoryGetDTO categoryGetDTO = DTOConverter.MapCategoryToCategoryGetDTO(category);

            return categoryGetDTO;
        }

        // PUT: api/Users/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutUser(string id, User user)
        {
            if (id != user.Id)
            {
                return BadRequest();
            }

            _context.Entry(user).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserExists(id))
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

        // POST: api/Users
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public async Task<ActionResult<User>> PostUser(UserPostDTO userPostDTO)
        {
            User user = DTOConverter.MapUserPostDTOToUser(userPostDTO, Guid.NewGuid().ToString());

            //user.Id = Guid.NewGuid().ToString();
            
            _context.Users.Add(user);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (UserExists(user.Id))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetUser", new { id = user.Id }, user);
        }

        // POST: api/Artefacts
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost("{id}/artefact")]
        public async Task<ActionResult<Artefact>> PostArtefact(string id, ArtefactPostDTO artefactPostDTO)
        {
            string artefactId = Guid.NewGuid().ToString();
            string? imageUrl = ImageUtilities.AddImage(artefactPostDTO.Image, artefactId);
            Artefact artefact = DTOConverter.MapArtefactPostDTOToArtefact(artefactPostDTO, artefactId, imageUrl);

            _context.Artefacts.Add(artefact);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (ArtefactExists(artefact.ArtefactId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetArtefact", new { id = artefact.ArtefactId }, artefact);
        }

        // POST: api/Categories
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost("{id}/categories")]
        public async Task<ActionResult<Category>> PostCategory(string id, CategoryPostDTO categoryPostDTO)
        {
            categoryPostDTO.UserId = id;

            Category category = DTOConverter.MapCategoryPostDTOToCategory(categoryPostDTO, Guid.NewGuid().ToString());
            
            _context.Categories.Add(category);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                if (CategoryExists(category.CategoryId))
                {
                    return Conflict();
                }
                else
                {
                    throw;
                }
            }

            return CreatedAtAction("GetCategory", new { id = category.CategoryId }, category);
        }

        // DELETE: api/Users/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/Artefacts/5
        [HttpDelete("{id}/artefact/{artefactId}")]
        public async Task<IActionResult> DeleteArtefact(string id, string artefactId)
        {
            var artefact = await _context.Artefacts.FindAsync(artefactId);
            if (artefact == null)
            {
                return NotFound();
            }

            _context.Artefacts.Remove(artefact);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // DELETE: api/Categories/5
        [HttpDelete("{id}/categories/{categoryId}")]
        public async Task<IActionResult> DeleteCategory(string id, string categoryId)
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

        private bool UserExists(string id)
        {
            return _context.Users.Any(e => e.Id == id);
        }

        private bool ArtefactExists(string id)
        {
            return _context.Artefacts.Any(e => e.ArtefactId == id);
        }

        private bool CategoryExists(string id)
        {
            return _context.Categories.Any(e => e.CategoryId == id);
        }
    }
}
