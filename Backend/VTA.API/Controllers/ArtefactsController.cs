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
using VTA.API.Utilities;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.AspNetCore.Authorization;

namespace VTA.API.Controllers
{
    [Authorize]
    [Route("api/{userId}/Users/Artefacts")]
    [ApiController]
    public class ArtefactsController : ControllerBase
    {
        private readonly ArtefactContext _context;

        public ArtefactsController(ArtefactContext context)
        {
            _context = context;
        }

        // GET: api/Artefacts
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts(string userId)
        {
            var Id = User.FindFirst("id")?.Value;

            if (Id != userId)
            {
                return Forbid();
            }
            List<Artefact> artefacts = await _context.Artefacts.Where(a => a.UserId == userId).ToListAsync();
            List<ArtefactGetDTO> artefactGetDTOs = new List<ArtefactGetDTO>();
            foreach (Artefact artefact in artefacts)
            {
                artefactGetDTOs.Add(DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()));
            }
            return artefactGetDTOs;
        }

        // GET: api/Artefacts/5
        [HttpGet("{artefactId}")]
        public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string userId, string artefactId)
        {
            var Id = User.FindFirst("id")?.Value;

            if (Id != userId)
            {
                return Forbid();
            }
            // var artefact = await _context.Artefacts.FindAsync(artefactId);

            var artefacts = await _context.Artefacts.Where(a => a.ArtefactId == artefactId).Where(a => a.UserId == userId).ToListAsync();
            var artefact = artefacts.First();

            if (artefact == null)
            {
                return NotFound();
            }

            ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

            return artefactGetDTO;
        }

        // PUT: api/Artefacts/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{artefactId}")]
        public async Task<IActionResult> PutArtefact(string userId, string artefactId, Artefact artefact)
        {
            var Id = User.FindFirst("id")?.Value;

            if (Id != userId)
            {
                return Forbid();
            }
            if (artefactId != artefact.ArtefactId)
            {
                return BadRequest();
            }

            _context.Entry(artefact).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!ArtefactExists(artefactId))
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

        // POST: api/Artefacts
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public async Task<ActionResult<Artefact>> PostArtefact(string userId, ArtefactPostDTO artefactPostDTO)
        {
            var Id = User.FindFirst("id")?.Value;

            if (Id != userId)
            {
                return Forbid();
            }

            string artefactId = Guid.NewGuid().ToString();
            string? imageUrl = ImageUtilities.AddImage(artefactPostDTO.Image, artefactId);
            Artefact artefact = DTOConverter.MapArtefactPostDTOToArtefact(artefactPostDTO, artefactId, imageUrl);
            artefact.UserId = userId;

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

            return CreatedAtAction("GetArtefact", new { userId = artefact.UserId, artefactId = artefact.ArtefactId }, artefact);
        }

        // DELETE: api/Artefacts/5
        [HttpDelete("{artefactId}")]
        public async Task<IActionResult> DeleteArtefact(string userId, string artefactId)
        {
            var Id = User.FindFirst("id")?.Value;

            if (Id != userId)
            {
                return Forbid();
            }

            var artefact = await _context.Artefacts.FindAsync(artefactId);
            if (artefact == null)
            {
                return NotFound();
            }

            _context.Artefacts.Remove(artefact);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool ArtefactExists(string id)
        {
            return _context.Artefacts.Any(e => e.ArtefactId == id);
        }
    }
}
