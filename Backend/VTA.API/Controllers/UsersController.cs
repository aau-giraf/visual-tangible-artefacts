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
    [AllowAnonymous]
    [HttpPost("test-upload")]
    public IActionResult TestUpload(IFormFile image)
    {
        if (image == null)
        {
            return BadRequest("Image file not received.");
        }
        return Ok("Image received successfully.");
    }

    [AllowAnonymous]
    [Route("SignUp")]
    [HttpPost]
    public async Task<ActionResult<UserLoginResponseDTO>> SingUp(UserSignupDTO userSignUp)
    {
        if (userSignUp == null)
        {
            return BadRequest();
        }

        User user = DTOConverter.MapUserSignUpDTOToUser(userSignUp, Guid.NewGuid().ToString());

        while (UserExists(user.Id))
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
            if (UserExists(user.Id))
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
            if (!UserExists(id))
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
    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var Id = User.FindFirst("id")?.Value;

        if (Id != id)
        {
            return Forbid();
        }
        var user = await _context.Users.FindAsync(id);
        if (user == null)
        {
            return NotFound();
        }

        foreach (var category in user.Categories)//We should remove all artefacts referenced by the user, therfore I've designed it like this 
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

    private bool UserExists(string id)
    {
        return _context.Users.Any(e => e.Id == id);
    }

    private string GenerateJwt(string userId, string name)
    {
        var secretKey = _config.GetValue<string>("Secret:SecretKey")
                        ?? Environment.GetEnvironmentVariable("JWT_SECRET")
                        ?? throw new InvalidOperationException("A JWT secret is required for token generation.");
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
            expires: DateTime.UtcNow.AddDays(1),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

}
