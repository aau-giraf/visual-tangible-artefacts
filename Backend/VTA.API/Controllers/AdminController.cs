using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Extensions;
using VTA.API.Services;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Controllers;

[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
[ApiController]
public class AdminController : ControllerBase
{
    private readonly VTAContext _context;
    private readonly IUserService _userService;
    private readonly IRelationService _relationService;

    public AdminController(VTAContext context, IUserService userService, IRelationService relationService)
    {
        _context = context;
        _userService = userService;
        _relationService = relationService;
    }

    [HttpGet("caregivers")]
    public async Task<ActionResult> GetCaregivers([FromQuery] int? skip, [FromQuery] int? take)
    {
        var query = _context.Users
            .Where(u => u.Role == UserRole.Caregiver)
            .AsNoTracking()
            .OrderBy(u => u.Username);

        var page = await query.ToPaginatedAsync(skip, take);
        return Ok(new PaginatedResponse<UserGetDTO>
        {
            Items = page.Items.Select(DTOConverter.MapUserToUserGetDTO).ToList(),
            TotalCount = page.TotalCount,
            Skip = page.Skip,
            Take = page.Take
        });
    }

    [HttpGet("children")]
    public async Task<ActionResult> GetChildren([FromQuery] int? skip, [FromQuery] int? take)
    {
        var query = _context.Users
            .Where(u => u.Role == UserRole.Child)
            .AsNoTracking()
            .OrderBy(u => u.Username);

        var page = await query.ToPaginatedAsync(skip, take);
        return Ok(new PaginatedResponse<UserGetDTO>
        {
            Items = page.Items.Select(DTOConverter.MapUserToUserGetDTO).ToList(),
            TotalCount = page.TotalCount,
            Skip = page.Skip,
            Take = page.Take
        });
    }

    [HttpGet("admins")]
    public async Task<ActionResult> GetAdmins([FromQuery] int? skip, [FromQuery] int? take)
    {
        var query = _context.Users
            .Where(u => u.Role == UserRole.Admin)
            .AsNoTracking()
            .OrderBy(u => u.Username);

        var page = await query.ToPaginatedAsync(skip, take);
        return Ok(new PaginatedResponse<UserGetDTO>
        {
            Items = page.Items.Select(DTOConverter.MapUserToUserGetDTO).ToList(),
            TotalCount = page.TotalCount,
            Skip = page.Skip,
            Take = page.Take
        });
    }

    [HttpPost("admins")]
    public async Task<ActionResult<UserGetDTO>> CreateAdmin(UserSignupDTO adminDto)
    {
        var (user, error) = await _userService.CreateAdminAsync(adminDto);

        if (error != null)
            return Conflict(error);

        return CreatedAtAction(nameof(GetAdmins), user);
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var deleted = await _userService.DeleteUserAsync(id);
        if (!deleted)
            return NotFound();

        return NoContent();
    }

    [HttpPost("users/{id}/make-admin")]
    public async Task<IActionResult> MakeUserAdmin(string id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound();
        }

        user.Role = UserRole.Admin;
        await _context.SaveChangesAsync();

        return Ok();
    }

    [HttpGet("pairings")]
    public async Task<ActionResult<IEnumerable<PairingDTO>>> GetPairings([FromQuery] int? skip, [FromQuery] int? take)
    {
        var pairings = await _relationService.GetAllPairingsAsync(activeOnly: true, skip: skip, take: take);
        return Ok(pairings);
    }

    [HttpPost("pairings")]
    public async Task<ActionResult> CreatePairing([FromBody] CreatePairingRequest request)
    {
        var (pairing, error) = await _relationService.CreatePairingAsync(request.CaregiverId, request.ChildId);

        if (error == "Pairing already exists")
            return Conflict("This pairing already exists");
        if (error != null)
            return BadRequest(error);

        return Ok(new { message = "Pairing created successfully", id = pairing!.Id });
    }

    [HttpDelete("pairings/{id}")]
    public async Task<IActionResult> DeletePairing(string id)
    {
        var removed = await _relationService.RemovePairingAsync(id);
        if (!removed)
            return NotFound();

        return NoContent();
    }
}