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

namespace VTA.API.Controllers
{
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

        [Route("Login")]
        [HttpPost]
        public async Task<ActionResult<UserLoginResponseDTO>> Login(UserLoginDTO userLoginForm)
        {
            if (userLoginForm == null)
            {
                return BadRequest();
            }

            User user = await _context.Users.FirstOrDefaultAsync(
                u => u.Username == userLoginForm.Username
                && u.Password == userLoginForm.Password);
            if (user == null)
            {
                return NotFound();
            }
            var userGetDTO = DTOConverter.MapUserToUserGetDTO(user);

            userGetDTO.Categories = user.Categories.Select(c => DTOConverter.MapCategoryToCategoryGetDTO(c)).ToList();

            for (int i = 0; i < userGetDTO.Categories.Count; i++)
            {
                userGetDTO.Categories.ElementAt(i).Artefacts = user.Categories.ElementAt(i).Artefacts
                    .Select(a => DTOConverter.MapArtefactToArtefactGetDTO(a, Request.Scheme, Request.Host.Value)).ToList();
            }

            var token = GenerateJwt(user.Id, user.Name);
            return new UserLoginResponseDTO
            {
                User = userGetDTO,
                Token = token
            };
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

            User user =  DTOConverter.MapUserSignUpDTOToUser(userSignUp, Guid.NewGuid().ToString());

            while (UserExists(user.Id))
            {
                user.Id = Guid.NewGuid().ToString();
            }

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
                User = userGetDTO,
                Token = token
            };
        }
        // GET: api/Users

        // [HttpGet]
        // public async Task<ActionResult<IEnumerable<UserGetDTO>>> GetUsers()
        // {
        //     List<User> users = await _context.Users.ToListAsync();
        //     List<UserGetDTO> userGetDTOs = new List<UserGetDTO>();
        //     foreach (User user in users)
        //     {
        //         userGetDTOs.Add(DTOConverter.MapUserToUserGetDTO(user));
        //     }
        //     return userGetDTOs;
        // }

        // // GET: api/Users/5
        // [Authorize]
        // [HttpGet("{id}")]
        // public async Task<ActionResult<UserGetDTO>> GetUser(string id)
        // {
        //     var user = await _context.Users.FindAsync(id);

        //     if (user == null)
        //     {
        //         return NotFound();
        //     }

        //     UserGetDTO userGetDTO = DTOConverter.MapUserToUserGetDTO(user);

        //     return userGetDTO;
        // }

        // // PUT: api/Users/5
        // // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        // [HttpPut("{id}")]
        // public async Task<IActionResult> PutUser(string id, User user)
        // {
        //     if (id != user.Id)
        //     {
        //         return BadRequest();
        //     }

        //     _context.Entry(user).State = EntityState.Modified;

        //     try
        //     {
        //         await _context.SaveChangesAsync();
        //     }
        //     catch (DbUpdateConcurrencyException)
        //     {
        //         if (!UserExists(id))
        //         {
        //             return NotFound();
        //         }
        //         else
        //         {
        //             throw;
        //         }
        //     }

        //     return NoContent();
        // }

        // // POST: api/Users
        // // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        // [HttpPost]
        // public async Task<ActionResult<User>> PostUser(UserPostDTO userPostDTO)
        // {
        //     User user = DTOConverter.MapUserPostDTOToUser(userPostDTO, Guid.NewGuid().ToString());

        //     _context.Users.Add(user);
        //     try
        //     {
        //         await _context.SaveChangesAsync();
        //     }
        //     catch (DbUpdateException)
        //     {
        //         if (UserExists(user.Id))
        //         {
        //             return Conflict();
        //         }
        //         else
        //         {
        //             throw;
        //         }
        //     }

        //     return CreatedAtAction("GetUser", new { id = user.Id }, user);
        // }

        // DELETE: api/Users/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(string id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound();
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool UserExists(string id)
        {
            return _context.Users.Any(e => e.Id == id);
        }

        private string GenerateJwt(string userId, string name)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretsSingleton.Secrets["SecretKey"]));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var claims = new[]
            {
                new Claim("id", userId),
                new Claim("name", name),
                //new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
                new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64)
            };
            var token = new JwtSecurityToken(
            issuer: _config.GetSection("Secret")["ValidIssuer"],
            audience: _config.GetSection("Secret")["ValidAudience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(1),
            signingCredentials: creds);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}
