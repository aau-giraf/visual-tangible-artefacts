using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]
[Route("api/Users/Artefacts")]
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
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts()
    {
        var userId = User.FindFirst("id")?.Value;

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
    public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;

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
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<IActionResult> PutArtefact(string artefactId, Artefact artefact)
    {
        var userId = User.FindFirst("id")?.Value;

        if (userId != artefact.UserId)
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
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<ActionResult<ArtefactGetDTO>> PostArtefact(ArtefactPostDTO artefactPostDTO)
    {
        var userId = User.FindFirst("id")?.Value;

        if (userId != artefactPostDTO.UserId)
        {
            return Forbid();
        }

        string artefactId = Guid.NewGuid().ToString();
        string? imageUrl = ImageUtilities.AddImage(artefactPostDTO.Image, artefactId, "Artefacts");
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
                //Chance of this happening is infinitely small ! But never zero !
                while (ArtefactExists(artefact.ArtefactId))
                {
                    artefact.ArtefactId = Guid.NewGuid().ToString();
                }
                await _context.SaveChangesAsync();
            }
            else
            {
                throw;
            }
        }

        var artefacts = await _context.Artefacts.FindAsync(artefactId);

        ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

        return Ok(artefactGetDTO);
    }

    // DELETE: api/Artefacts/5
    [HttpDelete("{artefactId}")]
    public async Task<IActionResult> DeleteArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        var artefact = await _context.Artefacts.FindAsync(artefactId);
        if (artefact == null)
        {
            return NotFound();
        }

        if (userId != artefact.UserId)
        {
            return Forbid();
        }
        ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts");

        _context.Artefacts.Remove(artefact);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool ArtefactExists(string id)
    {
        return _context.Artefacts.Any(e => e.ArtefactId == id);
    }
}
