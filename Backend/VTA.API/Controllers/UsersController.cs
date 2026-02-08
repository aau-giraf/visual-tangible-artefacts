using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using VTA.API.DTOs;
using VTA.API.Extensions;
using VTA.API.Services;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Controllers;
/// <summary>
/// Controller responsible for user-related endpoints.
/// </summary>
//Mark the entire controller to require a valid token
[Authorize]
[Route("api/[controller]")]//Define where all endpoints are
[ApiController]
public class UsersController(VTAContext context, IUserService userService, IRelationService relationService) : ControllerBase
{
    /// <summary>
    /// Login the user
    /// </summary>
    /// <param name="userLoginForm">username and password</param>
    /// <returns>A login object</returns>
    [AllowAnonymous]//Allows a user to not have a JWT
    [HttpPost("Login")] // = api/Users/Login
    public async Task<ActionResult<UserLoginResponseDTO>> Login(UserLoginDTO userLoginForm)
    {
        if (userLoginForm == null)
        {
            return BadRequest();
        }

        var result = await userService.AuthenticateAsync(userLoginForm.Username, userLoginForm.Password);
        if (result == null)
        {
            return NotFound();
        }

        return result;
    }

    /// <summary>
    /// Creates a new user
    /// </summary>
    /// <remarks>
    /// For more info on the Hashing algorithm see: <see cref="https://en.wikipedia.org/wiki/Bcrypt"/>
    /// </remarks>
    /// <param name="userSignUp">An object with all user info</param>
    /// <returns>A Login Object</returns>
    [AllowAnonymous]//Allows a user to not have a JWT
    [Route("SignUp")] // = api/Users/SignUp
    [HttpPost]
    public async Task<ActionResult<UserLoginResponseDTO>> SingUp(UserSignupDTO userSignUp)
    {
        if (userSignUp == null)
        {
            return BadRequest();
        }

        var (response, error) = await userService.RegisterAsync(userSignUp);

        if (error != null)
        {
            return Conflict(error);
        }

        return response!;
    }

    // GET: api/Users
    /// <summary>
    /// Get all users in the DB
    /// </summary>
    /// <returns>A paginated list of users</returns>
    [HttpGet]
    public async Task<ActionResult> GetUsers([FromQuery] int? skip, [FromQuery] int? take)
    {
        var query = context.Users
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

    // GET: api/Users/related-contacts
    /// <summary>
    /// Get related contacts for the current user.
    /// For caregivers: returns their connected children.
    /// For children: returns their connected caregivers.
    /// </summary>
    /// <returns>A list of related users (contacts)</returns>
    [HttpGet("related-contacts")]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetRelatedContacts()
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("User ID not found in token");
        }

        var contacts = await relationService.GetRelatedContactsAsync(userId);
        return Ok(contacts);
    }

    // GET: api/Users/{id}
    /// <summary>
    /// Get information about a specific user
    /// </summary>
    /// <returns>A user</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<UserGetDTO>> GetUser(string id)
    {
        var userId = User.FindFirst("id")?.Value;

        // This logic might need adjustment depending on whether an admin can fetch any user
        // For now, it's restricted to the logged-in user, but the route supports getting any user.
        User? user = await context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound();
        }

        UserGetDTO userGetDTO = DTOConverter.MapUserToUserGetDTO(user);

        return userGetDTO;
    }

    // PUT: api/Users/5
    // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
    /// <summary>
    /// Updates a users information (PUT HAS to have all fields in the User object filled out. A PATCH can have null values (which then aren't updated))
    /// </summary>
    /// <remarks>
    /// We should ALWAYS use DTO's as parameter & return in order to avoid circular dependecies and exposing data we shouldn't we however aren't using this method, so it has not been changed
    /// </remarks>
    /// <param name="id"></param>
    /// <param name="user"></param>
    /// <returns></returns>
    [HttpPut("{id}")]
    public async Task<IActionResult> PutUser(string id, User user)
    {
        if (id != user.Id)
        {
            return BadRequest();
        }

        context.Entry(user).State = EntityState.Modified;

        try
        {
            await context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!UserIdExists(id))
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

    // DELETE: api/Users/5
    /// <summary>
    /// Deletes a user using their ID. Also removes any artefact or category images from the filesystem
    /// </summary>
    /// <param name="id">The users ID</param>
    /// <returns>
    /// Status code 204 (No content) to the client on success<br />
    /// Status code 403 (Forbidden) if a client specifies any other ID than their own<br />
    /// Status code 404 (Not Found) if the user does not exist
    /// </returns>
    /// <remarks>
    /// We could remove the Id != id test (probably also the null check, since it *should* be impossible to get a null)
    /// </remarks>
    [HttpDelete("{id}")]//{} allows us to extract that part of the url as a variable
    public async Task<IActionResult> DeleteUser(string id)
    {
        var Id = User.FindFirst("id")?.Value;//Extract the id from the JWT (Dotnet infers that we are talking about the JWT)

        if (Id != id)//We are assuming users can be malicious and try to delete someone else, so Id's have to match
        {
            return Forbid();
        }

        var deleted = await userService.DeleteUserAsync(id);
        if (!deleted)
        {
            return NotFound();
        }

        return NoContent();
    }

    /// <summary>
    /// Update user settings (NameVisible, FieldCount)
    /// </summary>
    /// <param name="dto">User settings to update</param>
    /// <returns>Status code 204 (No Content) on success</returns>
    [HttpPatch]
    public async Task<IActionResult> PatchUser([FromBody] UserPatchDTO dto)
    {
        var userId = User.FindFirst("id")?.Value;

        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized("Invalid token");
        }

        var user = await context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound("User not found");
        }

        // Update fields if provided
        if (dto.NameVisible != null)
        {
            user.NameVisible = dto.NameVisible.Value;
        }
        if (dto.FieldCount != null)
        {
            user.FieldCount = dto.FieldCount.Value;
        }

        context.Entry(user).State = EntityState.Modified;
        await context.SaveChangesAsync();

        return NoContent();
    }

    private bool UserIdExists(string id)
    {
        return context.Users.Any(e => e.Id == id);
    }

}