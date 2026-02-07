using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Utilities;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Controllers;

[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
[ApiController]
public class AdminController : ControllerBase
{
    private readonly VTAContext _context;

    public AdminController(VTAContext context)
    {
        _context = context;
    }

    [HttpGet("caregivers")]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetCaregivers()
    {
        var caregivers = await _context.Users
            .Where(u => u.Role == UserRole.Caregiver)
            .AsNoTracking()
            .ToListAsync();

        var caregiversDto = caregivers.Select(DTOConverter.MapUserToUserGetDTO).ToList();
        return Ok(caregiversDto);
    }

    [HttpGet("children")]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetChildren()
    {
        var children = await _context.Users
            .Where(u => u.Role == UserRole.Child)
            .AsNoTracking()
            .ToListAsync();

        var childrenDto = children.Select(DTOConverter.MapUserToUserGetDTO).ToList();
        return Ok(childrenDto);
    }

    [HttpGet("admins")]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetAdmins()
    {
        var admins = await _context.Users
            .Where(u => u.Role == UserRole.Admin)
            .AsNoTracking()
            .ToListAsync();

        var adminsDto = admins.Select(DTOConverter.MapUserToUserGetDTO).ToList();
        return Ok(adminsDto);
    }

    [HttpPost("admins")]
    public async Task<ActionResult<UserGetDTO>> CreateAdmin(UserSignupDTO adminDto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == adminDto.Username))
        {
            return Conflict("Username already exists");
        }

        var admin = new User
        {
            Id = Guid.NewGuid().ToString(),
            Username = adminDto.Username,
            Name = adminDto.Name,
            Password = BCrypt.Net.BCrypt.HashPassword(adminDto.Password),
            Role = UserRole.Admin
        };

        _context.Users.Add(admin);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAdmins), DTOConverter.MapUserToUserGetDTO(admin));
    }

    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var user = await UserCleanupHelper.DeleteUserWithAssets(_context, id);

        if (user == null)
        {
            return NotFound();
        }

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
    public async Task<ActionResult<IEnumerable<object>>> GetPairings()
    {
        var pairings = await _context.Relations
            .Include(p => p.Caregiver)
            .Include(p => p.Child)
            .Where(p => p.IsActive)
            .AsNoTracking()
            .Select(p => new
            {
                id = p.Id,
                caregiverId = p.CaregiverId,
                childId = p.ChildId,
                caregiver = new { id = p.Caregiver.Id, name = p.Caregiver.Name, username = p.Caregiver.Username },
                child = new { id = p.Child.Id, name = p.Child.Name, username = p.Child.Username },
                createdAt = p.CreatedAt
            })
            .ToListAsync();

        return Ok(pairings);
    }

    [HttpPost("pairings")]
    public async Task<ActionResult> CreatePairing([FromBody] CreatePairingRequest request)
    {
        var caregiver = await _context.Users.FindAsync(request.CaregiverId);
        var child = await _context.Users.FindAsync(request.ChildId);

        if (caregiver == null || child == null)
        {
            return NotFound("One or both users not found");
        }

        if (caregiver.Role != UserRole.Caregiver)
        {
            return BadRequest("The specified caregiver is not a caregiver user");
        }

        if (child.Role != UserRole.Child)
        {
            return BadRequest("The specified child is not a child user");
        }

        var existingPairing = await _context.Relations
            .AnyAsync(p => p.CaregiverId == request.CaregiverId && p.ChildId == request.ChildId && p.IsActive);

        if (existingPairing)
        {
            return Conflict("This pairing already exists");
        }

        var pairing = new Relation
        {
            CaregiverId = request.CaregiverId,
            ChildId = request.ChildId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Relations.Add(pairing);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Pairing created successfully", id = pairing.Id });
    }

    [HttpDelete("pairings/{id}")]
    public async Task<IActionResult> DeletePairing(string id)
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
}