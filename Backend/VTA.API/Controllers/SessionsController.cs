using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;

namespace VTA.API.Controllers;

/// <summary>
/// Controller for managing sessions
/// </summary>
[Authorize(Roles = "Admin")]
[Route("api/[controller]")]
[ApiController]
public class SessionsController : ControllerBase
{
    private readonly VTAContext _context;

    /// <summary>
    /// Constructor for SessionsController
    /// </summary>
    public SessionsController(VTAContext context)
    {
        _context = context;
    }

    /// <summary>
    /// Get all sessions
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<SessionDTO>>> GetSessions()
    {
        var sessions = await _context.Sessions
            .Include(s => s.Caregiver)
            .Include(s => s.Child)
            .AsNoTracking()
            .ToListAsync();

        var sessionDtos = sessions.Select(s => new SessionDTO
        {
            Id = s.Id,
            CaregiverId = s.CaregiverId,
            ChildId = s.ChildId,
            State = s.State,
            CreatedAt = s.CreatedAt,
            StartedAt = s.StartedAt,
            EndedAt = s.EndedAt,
            Caregiver = DTOConverter.MapUserToUserGetDTO(s.Caregiver),
            Child = DTOConverter.MapUserToUserGetDTO(s.Child)
        }).ToList();

        return Ok(sessionDtos);
    }

    /// <summary>
    /// Get session by ID
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<SessionDTO>> GetSession(string id)
    {
        var session = await _context.Sessions
            .Include(s => s.Caregiver)
            .Include(s => s.Child)
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id);

        if (session == null)
        {
            return NotFound();
        }

        var sessionDto = new SessionDTO
        {
            Id = session.Id,
            CaregiverId = session.CaregiverId,
            ChildId = session.ChildId,
            State = session.State,
            CreatedAt = session.CreatedAt,
            StartedAt = session.StartedAt,
            EndedAt = session.EndedAt,
            Caregiver = DTOConverter.MapUserToUserGetDTO(session.Caregiver),
            Child = DTOConverter.MapUserToUserGetDTO(session.Child)
        };

        return Ok(sessionDto);
    }
}