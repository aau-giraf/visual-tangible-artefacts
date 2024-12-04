using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using VTA.API.DbContexts;
using VTA.API.DTOs;
using VTA.API.Models;
using VTA.API.Utilities;

namespace VTA.API.Controllers;
//Mark the entire controller to require a valid token
[Authorize]
[Route("api/Users")]//Define where all endpoints are
[ApiController]
public class UsersController : ControllerBase
{
    private readonly UserContext _context;
    private readonly IConfiguration _config;

    public UsersController(UserContext context, IConfiguration config)
    {
        _context = context;
        _config = config;
    }

    /// <summary>
    /// Login the user
    /// </summary>
    /// <param name="userLoginForm">username and password</param>
    /// <returns>A login object</returns>
    [AllowAnonymous]//Allows a user to not have a JWT
    [Route("Login")] // = api/Users/Login
    [HttpPost]
    public async Task<ActionResult<UserLoginResponseDTO>> Login(UserLoginDTO userLoginForm)
    {
        if (userLoginForm == null)
        {
            return BadRequest();
        }
        
        User? user = await _context.Users. //_context.Users (In the users table)
            FirstOrDefaultAsync( //find the first user
            u => u.Username == userLoginForm.Username);//where the users (u) username (.username) in the database matches userLoginForm.Username
        
        if (user == null)//If user not found
        {
            return NotFound();
        }

        if (!BCrypt.Net.BCrypt.Verify(userLoginForm.Password, user.Password)) //If the encrypted password is not found
        {
            return NotFound(); //We aren't telling them the password is wrong, just that *something* is wrong
        }

        var token = GenerateJwt(user.Id, user.Name);
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

        _context.Users.Add(user);
        try
        {
            await _context.SaveChangesAsync();
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
        var token = GenerateJwt(user.Id, user.Name);
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
    [HttpGet("Users")]
    public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetUsers()
    {
        List<User> users = await _context.Users.ToListAsync();
        List<UserGetDTO> userGetDTOs = new List<UserGetDTO>();
        foreach (User user in users)
        {
            userGetDTOs.Add(DTOConverter.MapUserToUserGetDTO(user));
        }
        return userGetDTOs;
    }

    // GET: api/Users/5
    /// <summary>
    /// Get information about a specific user
    /// </summary>
    /// <returns>A user</returns>
    [HttpGet]
    public async Task<ActionResult<UserGetDTO>> GetUser()
    {
        var userId = User.FindFirst("id")?.Value;

        User user = await _context.Users.FindAsync(userId);

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

        _context.Entry(user).State = EntityState.Modified;

        try
        {
            await _context.SaveChangesAsync();
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

        var user = await _context.Users.FindAsync(id);//Find user with 

        if (user == null)
        {
            return NotFound();
        }
        
        /*Categories and artefacts delete themselves upon calling .Remove (due to cascade talked about in a few lines
        * Therefore we remove all the images from the filesystem before we loose the refs*/
        foreach (var category in user.Categories)
        {
            foreach (var artefact in category.Artefacts)
            {
                ImageUtilities.DeleteImage(artefact.ArtefactId, "Artefacts");
            }
            ImageUtilities.DeleteImage(category.CategoryId, "Categories");
        }

        _context.Users.Remove(user);//MySQL is set to cascade delete, so upon calling SaveChangesAsync, the database automagically deletes all artefacts in this cat
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool UserIdExists(string id)
    {
        return _context.Users.Any(e => e.Id == id);//Returns true if any ID column within the *Users* table contains the ID 
    }
    private bool UsernameExists(string username)
    {
        return _context.Users.Any(e => e.Username == username);//Returns true if any username column within the *Users* table contains the username
    }

    /// <summary>
    /// Generates a Json Web Token used for granting access to the API endpoints marked with [Authorize]
    /// </summary>
    /// <param name="userId">The users ID, used within the encoded within the webtoken, both to create uniqueness but also to extract in functions</param>
    /// <param name="name">Only used to create more uniqueness</param>
    /// <returns>A valid JWT for this user</returns>
    /// <exception cref="InvalidOperationException"></exception>
    private string GenerateJwt(string userId, string name)
    {
        var secretKey = _config.GetValue<string>("Secret:SecretKey")
                        ?? Environment.GetEnvironmentVariable("JWT_SECRET") //Someone added this, why, i do not know, cause the key is stored in the appsettings.json not env variables 
                        ?? throw new InvalidOperationException("A JWT secret is required for token generation."); //Throw if no secret is found
        var validIssuer = "api.vta.com";
        var validAudience = "user.vta.com";

        //Here we add our "secret". The secret is encoded in all tokens, if you leak this, everyone can create valid keys for the API.
        //This key is created using a symmetric approach, you could make it assymetric, for more security
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256); // secure enough for this project

        var claims = new[]
        {
        new Claim("id", userId),
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
