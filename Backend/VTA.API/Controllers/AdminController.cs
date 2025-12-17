using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
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
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound();
        }

        _context.Users.Remove(user);
        await _context.SaveChangesAsync();

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

    // GET: api/Admin/sessions
    [HttpGet("sessions")]
    public async Task<ActionResult<IEnumerable<SessionGetDTO>>> GetSessions(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        [FromQuery] string? userId = null)
    {
        var query = _context.Sessions
            .Include(s => s.Caller)
            .Include(s => s.Callee)
            .AsNoTracking();

        if (startDate.HasValue)
        {
            query = query.Where(s => s.StartTime >= startDate.Value);
        }

        if (endDate.HasValue)
        {
            query = query.Where(s => s.StartTime <= endDate.Value);
        }

        if (!string.IsNullOrEmpty(userId))
        {
            query = query.Where(s => s.CallerId == userId || s.CalleeId == userId);
        }

        var sessions = await query
            .OrderByDescending(s => s.StartTime)
            .Select(s => new SessionGetDTO
            {
                Id = s.Id,
                CallerId = s.CallerId,
                CallerName = s.Caller.Name,
                CalleeId = s.CalleeId,
                CalleeName = s.Callee.Name,
                StartTime = s.StartTime.HasValue ? s.StartTime.Value : DateTime.MinValue,
                EndTime = s.EndTime,
                Duration = s.Duration,
                CallStatus = s.CallStatus
            })
            .ToListAsync();

        return Ok(sessions);
    }

    // GET: api/Admin/sessions/{id}
    [HttpGet("sessions/{id}")]
    public async Task<ActionResult<SessionGetDTO>> GetSession(int id)
    {
        var session = await _context.Sessions
            .Include(s => s.Caller)
            .Include(s => s.Callee)
            .AsNoTracking()
            .Where(s => s.Id == id)
            .Select(s => new SessionGetDTO
            {
                Id = s.Id,
                CallerId = s.CallerId,
                CallerName = s.Caller.Name,
                CalleeId = s.CalleeId,
                CalleeName = s.Callee.Name,
                StartTime = s.StartTime.HasValue ? s.StartTime.Value : DateTime.MinValue,
                EndTime = s.EndTime,
                Duration = s.Duration,
                CallStatus = s.CallStatus
            })
            .FirstOrDefaultAsync();

        if (session == null)
        {
            return NotFound();
        }

        return Ok(session);
    }

    // GET: api/Admin/sessions/statistics
    [HttpGet("sessions/statistics")]
    public async Task<ActionResult<SessionStatisticsDTO>> GetSessionStatistics(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null)
    {
        var query = _context.Sessions.AsNoTracking();

        if (startDate.HasValue)
        {
            query = query.Where(s => s.StartTime >= startDate.Value);
        }

        if (endDate.HasValue)
        {
            query = query.Where(s => s.StartTime <= endDate.Value);
        }

        var sessions = await query.ToListAsync();

        var statistics = new SessionStatisticsDTO
        {
            TotalSessions = sessions.Count,
            CompletedSessions = sessions.Count(s => s.CallStatus == CallStatus.Completed),
            RejectedSessions = sessions.Count(s => s.CallStatus == CallStatus.Rejected),
            FailedSessions = sessions.Count(s => s.CallStatus == CallStatus.Failed),
            TotalDuration = sessions
                .Where(s => s.Duration.HasValue)
                .Select(s => s.Duration!.Value)
                .Aggregate(TimeSpan.Zero, (sum, duration) => sum + duration),
            AverageDuration = sessions.Any(s => s.Duration.HasValue)
                ? TimeSpan.FromTicks((long)sessions
                    .Where(s => s.Duration.HasValue)
                    .Average(s => s.Duration!.Value.Ticks))
                : null
        };

        return Ok(statistics);
    }
}