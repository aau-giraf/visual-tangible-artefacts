using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;

[Authorize]//Lock all endpoints behind JWT
[Route("api/Users/Artefacts")]//We designed the route so that *Users* OWNS *Artefacts* and this route reflects it
[ApiController]
public class ArtefactsController : ControllerBase
{
    private readonly ArtefactContext _context;

    public ArtefactsController(ArtefactContext context)
    {
        _context = context;
    }

    // GET: api/Artefacts
    /// <summary>
    /// Gets all artefacts that a user owns
    /// </summary>
    /// <returns>An IEnumerable of artefacts</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ArtefactGetDTO>>> GetArtefacts()
    {
        var userId = User.FindFirst("id")?.Value;

        List<Artefact>? artefacts = await _context.Artefacts.Where(a => a.UserId == userId).ToListAsync();
        if (artefacts == null)
        {
            return NotFound();
        }
        List<ArtefactGetDTO> artefactGetDTOs = new List<ArtefactGetDTO>();
        foreach (Artefact artefact in artefacts)
        {
            artefactGetDTOs.Add(DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString()));
        }
        return artefactGetDTOs;
    }

    // GET: api/Artefacts/5
    /// <summary>
    /// Gets a specific artefact
    /// </summary>
    /// <param name="artefactId">The artefact to get</param>
    /// <returns>The specified artefact</returns>
    [HttpGet("{artefactId}")]
    public async Task<ActionResult<ArtefactGetDTO>> GetArtefact(string artefactId)
    {
        var userId = User.FindFirst("id")?.Value;

        var artefact = await _context.Artefacts.Where(a => a.UserId == userId).FirstOrDefaultAsync(a => a.ArtefactId == artefactId);
        if (artefact == null)
        {
            return NotFound();
        }

        ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

        return artefactGetDTO;
    }

    // PATCH: api/Artefacts/5
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Updates an artefacts information
    /// </summary>
    /// <param name="dto"></param>
    /// <returns></returns>
    [HttpPatch]
    [DisableRequestSizeLimit, RequestFormLimits(MultipartBodyLengthLimit = Int32.MaxValue, ValueLengthLimit = Int32.MaxValue)]
    public async Task<IActionResult> PatchArtefact([FromForm] ArtefactPatchDTO dto)
    {
        var artefact = _context.Artefacts.Find(dto.ArtefactId);

        if (artefact == null)
        {
            return BadRequest();
        }

        if (dto.ArtefactIndex != null && artefact.ArtefactIndex != dto.ArtefactIndex)
        {
            artefact.ArtefactIndex = dto.ArtefactIndex.Value;
        }
        if (!string.IsNullOrEmpty(dto.Name) && artefact.Name != dto.Name)
        {
            artefact.Name = dto.Name;
        }
        if (dto.Image != null)
        {
            ImageUtilities.DeleteImage(artefact.CategoryId, "Categories");
            ImageUtilities.AddImage(dto.Image, artefact.CategoryId, "Categories");
        }

        _context.Entry(artefact).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ArtefactExists(artefact.CategoryId))
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
    /// <summary>
    /// Creates a new artefact
    /// </summary>
    /// <param name="ArtefactPostDTO">An object with all artefact info</param>
    /// <returns>
    /// Status code 200 (Ok) to the client on success (Ok should also have the item with it)<br />
    /// Status code 403 (Forbidden) if a client tries to add an artefact to someone else<br />
    /// </returns>
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

        ArtefactGetDTO artefactGetDTO = DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host.ToString());

        return Ok(artefactGetDTO);
    }

    // DELETE: api/Artefacts/5
    /// <summary>
    /// Deletes an artefact using its ID
    /// </summary>
    /// <param name="artefactId">The artefacts ID</param>
    /// <returns>
    /// Status code 204 (No content) to the client on success<br />
    /// Status code 403 (Forbidden) if a client tries to delete an artefact that they do not own<br />
    /// Status code 404 (Not Found) if the artefact does not exist
    /// </returns>
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
