using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing caregiver-child pairings
/// </summary>
[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
[ApiController]
public class RelationController : ControllerBase
{
    private readonly VTAContext _context;

    /// <summary>
    /// Constructor for RelationController
    /// </summary>
    public RelationController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all pairings
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PairingDTO>>> GetPairings()
    {
        var pairings = await _context.Relations
            .Include(p => p.Caregiver)
            .Include(p => p.Child)
            .AsNoTracking()
            .ToListAsync();

        var pairingDtos = pairings.Select(p => new PairingDTO
        {
            Id = p.Id,
            CaregiverId = p.CaregiverId,
            ChildId = p.ChildId,
            IsActive = p.IsActive,
            CreatedAt = p.CreatedAt,
            Caregiver = DTOConverter.MapUserToUserGetDTO(p.Caregiver),
            Child = DTOConverter.MapUserToUserGetDTO(p.Child)
        }).ToList();

        return Ok(pairingDtos);
    }

    /// <summary>
    /// Get pairings for a specific caregiver
    /// </summary>
    [HttpGet("caregiver/{caregiverId}")]
    public async Task<ActionResult<IEnumerable<PairingDTO>>> GetPairingsForCaregiver(string caregiverId)
    {
        var pairings = await _context.Relations
            .Include(p => p.Caregiver)
            .Include(p => p.Child)
            .Where(p => p.CaregiverId == caregiverId && p.IsActive)
            .AsNoTracking()
            .ToListAsync();

        var pairingDtos = pairings.Select(p => new PairingDTO
        {
            Id = p.Id,
            CaregiverId = p.CaregiverId,
            ChildId = p.ChildId,
            IsActive = p.IsActive,
            CreatedAt = p.CreatedAt,
            Caregiver = DTOConverter.MapUserToUserGetDTO(p.Caregiver),
            Child = DTOConverter.MapUserToUserGetDTO(p.Child)
        }).ToList();

        return Ok(pairingDtos);
    }

    /// <summary>
    /// Create a new pairing between caregiver and child
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PairingDTO>> CreatePairing(CreatePairingDTO createDto)
    {
        var caregiver = await _context.Users.FindAsync(createDto.CaregiverId);
        if (caregiver == null || caregiver.Role != UserRole.Caregiver)
        {
            return BadRequest("Invalid caregiver");
        }

        var child = await _context.Users.FindAsync(createDto.ChildId);
        if (child == null || child.Role != UserRole.Child)
        {
            return BadRequest("Invalid child");
        }

        var existingPairing = await _context.Relations
            .FirstOrDefaultAsync(p => p.CaregiverId == createDto.CaregiverId &&
                                    p.ChildId == createDto.ChildId &&
                                    p.IsActive);

        if (existingPairing != null)
        {
            return Conflict("Pairing already exists");
        }

        var pairing = new Relation
        {
            CaregiverId = createDto.CaregiverId,
            ChildId = createDto.ChildId
        };

        _context.Relations.Add(pairing);
        await _context.SaveChangesAsync();

        var pairingDto = new PairingDTO
        {
            Id = pairing.Id,
            CaregiverId = pairing.CaregiverId,
            ChildId = pairing.ChildId,
            IsActive = pairing.IsActive,
            CreatedAt = pairing.CreatedAt,
            Caregiver = DTOConverter.MapUserToUserGetDTO(caregiver),
            Child = DTOConverter.MapUserToUserGetDTO(child)
        };

        return CreatedAtAction(nameof(GetPairings), pairingDto);
    }

    /// <summary>
    /// Remove a pairing (set as inactive)
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> RemovePairing(string id)
    {
        var pairing = await _context.Relations.FindAsync(id);
        if (pairing == null)
        {
            return NotFound();
        }

        pairing.IsActive = false;
        await _context.SaveChangesAsync();

        return NoContent();
    }

    /// <summary>
    /// Remove pairing by caregiver and child IDs
    /// </summary>
    [HttpDelete]
    public async Task<IActionResult> RemovePairingByIds([FromBody] CreatePairingDTO removeDto)
    {
        var pairing = await _context.Relations
            .FirstOrDefaultAsync(p => p.CaregiverId == removeDto.CaregiverId &&
                                    p.ChildId == removeDto.ChildId &&
                                    p.IsActive);

        if (pairing == null)
        {
            return NotFound();
        }

        pairing.IsActive = false;
        await _context.SaveChangesAsync();

        return NoContent();
    }
}