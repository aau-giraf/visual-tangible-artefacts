using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VTA.API.DTOs;
using VTA.API.Services;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing caregiver-child pairings
/// </summary>
[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
[ApiController]
public class RelationController : ControllerBase
{
    private readonly IRelationService _relationService;

    /// <summary>
    /// Constructor for RelationController
    /// </summary>
    public RelationController(IRelationService relationService)
    {
        _relationService = relationService;
    }

    /// <summary>
    /// Get all pairings
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PairingDTO>>> GetPairings([FromQuery] int? skip, [FromQuery] int? take)
    {
        var pairings = await _relationService.GetAllPairingsAsync(skip: skip, take: take);
        return Ok(pairings);
    }

    /// <summary>
    /// Get pairings for a specific caregiver
    /// </summary>
    [HttpGet("caregiver/{caregiverId}")]
    public async Task<ActionResult<IEnumerable<PairingDTO>>> GetPairingsForCaregiver(string caregiverId, [FromQuery] int? skip, [FromQuery] int? take)
    {
        var pairings = await _relationService.GetPairingsForCaregiverAsync(caregiverId, skip, take);
        return Ok(pairings);
    }

    /// <summary>
    /// Create a new pairing between caregiver and child
    /// </summary>
    [HttpPost]
    public async Task<ActionResult<PairingDTO>> CreatePairing(CreatePairingDTO createDto)
    {
        var (pairing, error) = await _relationService.CreatePairingAsync(createDto.CaregiverId, createDto.ChildId);

        if (error == "Pairing already exists")
            return Conflict(error);
        if (error != null)
            return BadRequest(error);

        return CreatedAtAction(nameof(GetPairings), pairing);
    }

    /// <summary>
    /// Remove a pairing (set as inactive)
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> RemovePairing(string id)
    {
        var removed = await _relationService.RemovePairingAsync(id);
        if (!removed)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Remove pairing by caregiver and child IDs
    /// </summary>
    [HttpDelete]
    public async Task<IActionResult> RemovePairingByIds([FromBody] CreatePairingDTO removeDto)
    {
        var removed = await _relationService.RemovePairingByIdsAsync(removeDto.CaregiverId, removeDto.ChildId);
        if (!removed)
            return NotFound();

        return NoContent();
    }
}