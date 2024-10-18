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
    [Route("api/ArtefactsController")]
    [ApiController]
    public class ArtefactsController : ControllerBase
    {
        private readonly ArtefactContext _context;

        public ArtefactsController(ArtefactContext context)
        {
            _context = context;
        }

        // TEST DEPLOYMENT ENDPOINT
        // GET: api/ArtefactsController/TestDeployment
        [HttpGet("TestDeployment")]
        public ActionResult<string> TestDeployment()
        {
            return "Deployment Successful!";
        }

        // GET: api/Artefacts
        [HttpGet]
        public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts()
        {
            List<Artefact> artefacts = await _context.Artefacts.ToListAsync();
            List<ArtefactGetDTO> artefactGetDTOs = new List<ArtefactGetDTO>();
            foreach (Artefact artefact in artefacts)
            {
                artefactGetDTOs.Add(DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()));
            }
            return artefactGetDTOs;
        }

        // GET: api/Artefacts/5
        [HttpGet("{id}")]
        public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string id)
        {
            var artefact = await _context.Artefacts.FindAsync(id);

            if (artefact == null)
            {
                return NotFound();
            }

            ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

            return artefactGetDTO;
        }

        // PUT: api/Artefacts/5
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutArtefact(string id, Artefact artefact)
        {
            if (id != artefact.ArtefactId)
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
                if (!ArtefactExists(id))
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

        // DELETE: api/Artefacts/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteArtefact(string id)
        {
            var artefact = await _context.Artefacts.FindAsync(id);
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
