using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Controllers;
//Mark the entire controller to require a valid token
[Authorize]
[Route("api/[controller]")]//Define where all endpoints are
[ApiController]
public class ContactsController(VTAContext context, IConfiguration config, ILogger<ContactsController> logger) : ControllerBase
{

    // GET: api/Contacts
    /// <summary>
    /// Get related contacts for the current user.
    /// For caregivers: returns their connected children.
    /// For children: returns their connected caregivers.
    /// </summary>
    /// <returns>A list of related users (contacts)</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetContacts()
    {
        logger.LogInformation("Fetching contacts for the current user.");

        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("User ID not found in token");
        }

        logger.LogInformation("Fetching contacts for user ID: {userId}", userId);

        var currentUser = await context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId);

        if (currentUser == null)
        {
            return NotFound("Current user not found");
        }

        List<UserGetDTO> relatedUsers = new List<UserGetDTO>();

        if (currentUser.Role == UserRole.Caregiver)
        {
            // Get all children connected to this caregiver
            var children = await context.Relations
                .Where(r => r.CaregiverId == userId && r.IsActive)
                .Include(r => r.Child)
                .AsNoTracking()
                .ToListAsync();

            relatedUsers = children
                .Select(r => DTOConverter.MapUserToUserGetDTO(r.Child))
                .ToList();
        }
        else if (currentUser.Role == UserRole.Child)
        {
            // Get all caregivers connected to this child
            var caregivers = await context.Relations
                .Where(r => r.ChildId == userId && r.IsActive)
                .Include(r => r.Caregiver)
                .AsNoTracking()
                .ToListAsync();

            relatedUsers = caregivers
                .Select(r => DTOConverter.MapUserToUserGetDTO(r.Caregiver))
                .ToList();
        }

        return relatedUsers;
    }
}