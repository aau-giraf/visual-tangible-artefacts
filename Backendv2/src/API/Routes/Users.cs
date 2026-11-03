<<<<<<< HEAD
using Microsoft.AspNetCore.Http;

namespace Backendv2.src.API.Routes.Users;


public static class usersRoutes()
{
    public static RoutesGroupBuilder MapUsersRoutes(this RouteGroupBuilder group)
    {
        // GET: api/Users
        // Get all users
        group.MapGet("/", () => controller.GetAll());

        // GET: api/Users/{id}
        group.MapGet("/{userId}", (int userId) => controller.GetByid(userId));

        //POST: /auth/register
        group.MapPost("/auth/register", () => controller.Create());

        //PATCH: /users/{id}
        group.MapPatch("/{userId}", () => controller);

        //PUT: /users/{id}/password
        group.MapPut("/{userId}/password", () => controller);
        
        //DELETE: /users/{id}
        group.MapDelete("/{userId}", (int userId) => controller.Delete(userId));
        
        //GET: /users/{id}/settings
        group.MapGet("/{userId}/settings", () => controller);
        
        //PATCH: /users/{id}/settings
        group.MapPatch("/{userId}/settings", () => controller);


        return group;

    }
}









    
=======

namespace Backendv2.src.API.Routes;


public class VTARoutes()
{








}


// GET: api/Users
    /// Get all users in the DB
    /// Returns a paginated list of users
    /*[HttpGet]
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
    }*/








// GET: api/Users/{id}
    /// Get information about a specific user
    /// Returns a user
    /*[HttpGet("{id}")]
    public async Task<ActionResult<UserGetDTO>> GetUser(string id)
    {
        var userId = User.FindFirst("id")?.Value;

        User? user = await context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound();
        }

        UserGetDTO userGetDTO = DTOConverter.MapUserToUserGetDTO(user);

        return userGetDTO;
    }*/

// rewrite......
//POST: /auth/register
    /// Creates a new user
    /// For more info on the Hashing algorithm see: <see href="https://en.wikipedia.org/wiki/Bcrypt"/>
    /// <param name="userSignUp">An object with all user info</param>
    /// Returns a Login Object
    /*[AllowAnonymous]//Allows a user to not have a JWT
    [Route("register")] // = api/Users/register
    [HttpPost]
    public async Task<ActionResult<UserLoginResponseDTO>> Register(UserRegisterDTO userRegister)
    {
        if (userRegister == null)
        {
            return BadRequest();
        }

        var (response, error) = await userService.RegisterAsync(userRegister);

        if (error != null)
        {
            return Conflict(error);
        }

        return response!;
    }*/


//PATCH: /users/{id}

//Write from bottom....
//PUT: /users/{id}/password

//DELETE: /users/{id}
    /// Deletes a user using their ID. Also removes any artefact or category images from the filesystem
    /// <param name="id">The users ID</param>
    /// Returns:
    /// Status code 204 (No content) to the client on success
    /// Status code 403 (Forbidden) if a client specifies any other ID than their own
    /// Status code 404 (Not Found) if the user does not exist
    
    /// We could remove the Id != id test (probably also the null check, since it *should* be impossible to get a null)
    
    /*[HttpDelete("{id}")]//{} allows us to extract that part of the url as a variable
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
    }*/

//GET: /users/{id}/settings

//PATCH: /users/{id}/settings
    /// Update user settings (NameVisible, FieldCount)
    /// <param name="dto">User settings to update</param>
    /// Returns status code 204 (No Content) on success
    /*[HttpPatch]
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
<<<<<<< HEAD
    }
>>>>>>> 76118e6 (created file users.cs in routes)
=======
    }*/
>>>>>>> 733d2ac (blabla)
    