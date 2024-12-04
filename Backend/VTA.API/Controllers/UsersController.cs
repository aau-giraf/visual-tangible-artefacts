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
[Route("api/Users")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly UserContext _context;

    private readonly SecretsProvider _secretsSingleton;

    private readonly IConfiguration _config;

    public UsersController(UserContext context, SecretsProvider secretSingleton, IConfiguration config)
    {
        _context = context;
        _secretsSingleton = secretSingleton;
        _config = config;
    }

    [AllowAnonymous]
    [Route("Login")]
    [HttpPost]
    public async Task<ActionResult<UserLoginResponseDTO>> Login(UserLoginDTO userLoginForm)
    {
        if (userLoginForm == null)
        {
            return BadRequest();
        }
        User? user = await _context.Users.
            FirstOrDefaultAsync(
            u => u.Username == userLoginForm.Username);
        if (user == null)
        {
            return NotFound();
        }

        if (!BCrypt.Net.BCrypt.Verify(userLoginForm.Password, user.Password))
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

    /**/
    [AllowAnonymous]
    [Route("SignUp")]
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
    [HttpDelete("{id}")]
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
