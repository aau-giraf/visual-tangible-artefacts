using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using VTA.API.DTOs;
using VTA.API.Services;

namespace VTA.API.Controllers;
//Mark the entire controller to require a valid token
[Authorize]
[Route("api/[controller]")]//Define where all endpoints are
[ApiController]
public class ContactsController(IRelationService relationService) : ControllerBase
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
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("User ID not found in token");
        }

        var contacts = await relationService.GetRelatedContactsAsync(userId);
        return Ok(contacts);
    }
}