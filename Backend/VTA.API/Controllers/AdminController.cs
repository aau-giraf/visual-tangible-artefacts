using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Extensions;
using VTA.API.Services;
using VTA.Data.DbContexts;
using VTA.Data.Models;

//A controller handling admin functionality.
namespace VTA.API.Controllers;

[Authorize(Roles = "Admin")] //Prevents normal users from accessing admin endpoints.
[Route("api/[controller]")] //Base URL for adminController, stored in an ASP.NET CORE API.
[ApiController]
public class AdminController : ControllerBase
{
    private readonly VTAContext _context;
    private readonly IUserService _userService;
    private readonly IRelationService _relationService;

//AdminController object
    public AdminController(VTAContext context, IUserService userService, IRelationService relationService)
    {
        _context = context;
        _userService = userService;
        _relationService = relationService;
    }

//API enpoint that gets a pagenated list of all users who are caregivers.
    [HttpGet("caregivers")] 
    //Method responds to an Http get request ending in caregivers, full route would be GET /api/Admin/caregivers
    // int? means integer is nullable, to use skip and take for pagenated response.
    public async Task<ActionResult> GetCaregivers([FromQuery] int? skip, [FromQuery] int? take)
    {
        var query = _context.Users
            .Where(u => u.Role == UserRole.Caregiver) //Filters the users to be only cargivers.
            .AsNoTracking() //Tells Entiy framwork I am only reading the users, no need to track changes.
            .OrderBy(u => u.Username); //Sorts caregivers by username, in alfabetical order.

//Uses skip and take to retreive one page, if example route is /api/Admin/caregivers?skip=20&take=10
//IF we have 100 users, it would skip first 20 and take next 10 and return a pagenated response.
//Takes IQueryable<User> returns PaginatedResponse<User>
        var page = await query.ToPaginatedAsync(skip, take);
        //Takes paginated database result, converts users to DTOs and sends the resukt back to the API caller.
        return Ok(new PaginatedResponse<UserGetDTO>
        {
            //page.items contains database user objects.
            /*Select(DTOConverter.MapUserToUserGetDTO) because you dont want to send entire user object 
            to the frontend, like password hashes.*/
            Items = page.Items.Select(DTOConverter.MapUserToUserGetDTO).ToList(),
            // copy pagenation information to new response.
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

//Receive admin sign up information, ask user service to create admin.
    [HttpPost("admins")]
    public async Task<ActionResult<UserGetDTO>> CreateAdmin(UserSignupDTO adminDto)
    {
        //Creates admin user from adminDto that contains the relevant info.
        var (user, error) = await _userService.CreateAdminAsync(adminDto);

    //Return 409 conflict if creation fails.
        if (error != null)
            return Conflict(error);

    //Return 201 created with created user.
        return CreatedAtAction(nameof(GetAdmins), user); //nameof(GetAdmins) gets name of GetAdmins method as a string.
    }

//Delete a user by id
    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var deleted = await _userService.DeleteUserAsync(id); //Delete user and all asociated assets.
        if (!deleted)
            return NotFound(); //status 404 not found response.

        return NoContent(); //User effectivly deleted.
    }


//Finds user by id and change their role to admin.
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