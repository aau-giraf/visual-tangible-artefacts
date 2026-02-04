using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using VTA.API.DTOs;
using VTA.API.Utilities;
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
public class UsersController(VTAContext context, IConfiguration config) : ControllerBase
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

        User? user = await context.Users //_context.Users (In the users table)
            .AsNoTracking() // Read-only query for login
            .FirstOrDefaultAsync( //find the first user
            u => u.Username == userLoginForm.Username);//where the users (u) username (.username) in the database matches userLoginForm.Username

        if (user == null)//If user not found
        {
            return NotFound();
        }

        if (!BCrypt.Net.BCrypt.Verify(userLoginForm.Password, user.Password)) //If the hashed password is not found
        {
            return NotFound(); //We aren't telling them the password is wrong, just that *something* is wrong
        }

        var token = GenerateJwt(user);
        return new UserLoginResponseDTO
        {
            Token = token,
            userId = user.Id
        };
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
        if (UsernameExists(userSignUp.Username))
        {
            return Conflict("Username already exists");
        }
        User user = DTOConverter.MapUserSignUpDTOToUser(userSignUp, Guid.NewGuid().ToString());

        while (UserIdExists(user.Id))
        {
            user.Id = Guid.NewGuid().ToString();
        }

        user.Password = BCrypt.Net.BCrypt.HashPassword(user.Password);

        context.Users.Add(user);

        var defaultBoard = new SavedBoard
        {
            Id = Guid.NewGuid().ToString(),
            Name = "Board1",
            UserId = user.Id,
            CreatedDate = DateTime.UtcNow
        };

        context.SavedBoards.Add(defaultBoard);

        try
        {
            await context.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            if (UserIdExists(user.Id))
            {
                return Conflict();
            }
            else
            {
                throw;
            }
        }

        return await AutoSignIn(user);
    }

    /// <summary>
    /// Requested by the front-end. The intended functionality is pretty clear.
    /// </summary>
    /// <remarks>
    /// See <see cref="UsersController.SignUp"/>Refer to the SignUp method for user registration details.
    /// See <see cref="VTA.API.DTOs.UserLoginResponseDTO"/>Refer to the UserLoginResponseDTO for details on the login response format.
    /// </remarks>
    /// <param name="user">The user that was just created in SignUp.</param>
    /// <returns>A Login object containing authentication details.</returns>
    private async Task<ActionResult<UserLoginResponseDTO>> AutoSignIn(User user)
    {
        var userGetDTO = DTOConverter.MapUserToUserGetDTO(user);
        var token = GenerateJwt(user);
        return new UserLoginResponseDTO
        {
            Token = token,
            userId = user.Id
        };
    }

    // GET: api/Users
    /// <summary>
    /// Get all users in the DB (I thought i had removed this?)
    /// </summary>
    /// <remarks>
    /// This could be alted to get all users tied to a parent/pedagogue/teacher
    /// </remarks>
    /// <returns>A list of users</returns>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetUsers()
    {
        List<User> users = await context.Users
            .AsNoTracking()
            .ToListAsync();

        var userGetDTOs = users
            .Select(user => DTOConverter.MapUserToUserGetDTO(user))
            .ToList();

        return userGetDTOs;
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

        // Load user with all related entities (Categories and their Artefacts)
        var user = await context.Users
            .Include(u => u.Categories)
                .ThenInclude(c => c.Artefacts)
            .Include(u => u.SavedBoards)
                .ThenInclude(sb => sb.SavedArtefacts)
            .FirstOrDefaultAsync(u => u.Id == id);

        if (user == null)
        {
            return NotFound();
        }

        /*Categories and artefacts delete themselves upon calling .Remove (due to cascade talked about in a few lines
        * Therefore we remove all the images and sounds from the filesystem before we loose the refs*/
        foreach (var category in user.Categories)
        {
            foreach (var artefact in category.Artefacts)
            {
                ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts", id);
                // Also delete sound files if they exist
                try
                {
                    SoundUtilities.DeleteSound(artefact.ArtefactId, id);
                }
                catch { }
            }
            ImageUtilities.DeleteImage(category.CategoryId, "Categories", id);
        }

        // Delete saved boards and their data
        foreach (var savedBoard in user.SavedBoards.ToList())
        {
            // Delete snapshot file if it exists
            if (!string.IsNullOrEmpty(savedBoard.SnapshotPath))
            {
                try
                {
                    var snapshotPath = Path.Combine("wwwroot", savedBoard.SnapshotPath.TrimStart('/'));
                    if (System.IO.File.Exists(snapshotPath))
                    {
                        System.IO.File.Delete(snapshotPath);
                    }
                }
                catch { }
            }

            foreach (var savedArtefact in savedBoard.SavedArtefacts.ToList())
            {
                context.SavedArtefacts.Remove(savedArtefact);
            }

            context.SavedBoards.Remove(savedBoard);
        }

        context.Users.Remove(user);//MySQL is set to cascade delete, so upon calling SaveChangesAsync, the database automagically deletes all artefacts in this cat
        await context.SaveChangesAsync();

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
        return context.Users.Any(e => e.Id == id);//Returns true if any ID column within the *Users* table contains the ID
    }
    private bool UsernameExists(string username)
    {
        return context.Users.Any(e => e.Username == username);//Returns true if any username column within the *Users* table contains the username
    }

    /// <summary>
    /// Generates a Json Web Token used for granting access to the API endpoints marked with [Authorize]
    /// </summary>
    /// <param name="user">The user object containing ID, name, and role information</param>
    /// <returns>A valid JWT for this user</returns>
    /// <exception cref="InvalidOperationException"></exception>
    private string GenerateJwt(User user)
    {
        // Get secret from configuration first, fall back to environment variable
        // Use helper variables to properly handle empty strings (not just null)
        var configSecret = config.GetValue<string>("Secret:SecretKey");
        var envSecret = Environment.GetEnvironmentVariable("JWT_SECRET");
        var secretKey = !string.IsNullOrWhiteSpace(configSecret) ? configSecret
                      : !string.IsNullOrWhiteSpace(envSecret) ? envSecret
                      : throw new InvalidOperationException("A JWT secret is required for token generation.");
        var validIssuer = "api.vta.com";
        var validAudience = "user.vta.com";

        //Here we add our "secret". The secret is encoded in all tokens, if you leak this, everyone can create valid keys for the API.
        //This key is created using a symmetric approach, you could make it assymetric, for more security
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256); // secure enough for this project

        var claims = new[]
        {
        new Claim("id", user.Id),
        new Claim("role", user.Role.ToString()),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64)
    };

        var token = new JwtSecurityToken(
            issuer: validIssuer,
            audience: validAudience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

}