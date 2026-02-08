using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using VTA.API.DTOs;
using VTA.API.Utilities;
using VTA.Data.DbContexts;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Concrete implementation of <see cref="IUserService"/>.
/// Consolidates auth + user CRUD that was duplicated between
/// UsersController and AdminController.
/// </summary>
public class UserService : IUserService
{
    private readonly VTAContext _context;
    private readonly IConfiguration _config;
    private readonly ILogger<UserService> _logger;

    public UserService(
        VTAContext context,
        IConfiguration config,
        ILogger<UserService> logger)
    {
        _context = context;
        _config = config;
        _logger = logger;
    }

    /// <inheritdoc />
    public async Task<UserLoginResponseDTO?> AuthenticateAsync(string username, string password)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Username == username);

        if (user == null)
            return null;

        if (!BCrypt.Net.BCrypt.Verify(password, user.Password))
            return null;

        return new UserLoginResponseDTO
        {
            Token = GenerateJwt(user),
            userId = user.Id
        };
    }

    /// <inheritdoc />
    public async Task<(UserLoginResponseDTO? Response, string? Error)> RegisterAsync(UserSignupDTO dto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == dto.Username))
            return (null, "Username already exists");

        var user = DTOConverter.MapUserSignUpDTOToUser(dto, Guid.NewGuid().ToString());

        // Guarantee unique ID (astronomically unlikely collision, but guarded)
        while (await _context.Users.AnyAsync(u => u.Id == user.Id))
            user.Id = Guid.NewGuid().ToString();

        user.Password = BCrypt.Net.BCrypt.HashPassword(user.Password);

        _context.Users.Add(user);

        // Every new user gets a default board
        _context.SavedBoards.Add(new SavedBoard
        {
            Id = Guid.NewGuid().ToString(),
            Name = "Board1",
            UserId = user.Id,
            CreatedDate = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();

        var response = new UserLoginResponseDTO
        {
            Token = GenerateJwt(user),
            userId = user.Id
        };
        return (response, null);
    }

    /// <inheritdoc />
    public async Task<(UserGetDTO? User, string? Error)> CreateAdminAsync(UserSignupDTO dto)
    {
        if (await _context.Users.AnyAsync(u => u.Username == dto.Username))
            return (null, "Username already exists");

        var admin = new User
        {
            Id = Guid.NewGuid().ToString(),
            Username = dto.Username,
            Name = dto.Name,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Role = UserRole.Admin
        };

        _context.Users.Add(admin);
        await _context.SaveChangesAsync();

        return (DTOConverter.MapUserToUserGetDTO(admin), null);
    }

    /// <inheritdoc />
    public async Task<bool> DeleteUserAsync(string userId)
    {
        var user = await UserCleanupHelper.DeleteUserWithAssets(_context, userId);
        return user != null;
    }

    /// <inheritdoc />
    public string GenerateJwt(User user)
    {
        var configSecret = _config.GetValue<string>("Secret:SecretKey");
        var envSecret = Environment.GetEnvironmentVariable("JWT_SECRET");
        var secretKey = !string.IsNullOrWhiteSpace(configSecret) ? configSecret
                      : !string.IsNullOrWhiteSpace(envSecret) ? envSecret
                      : throw new InvalidOperationException(
                            "A JWT secret is required for token generation.");

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim("id", user.Id),
            new Claim("role", user.Role.ToString()),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim(JwtRegisteredClaimNames.Iat,
                DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(),
                ClaimValueTypes.Integer64)
        };

        var token = new JwtSecurityToken(
            issuer: "api.vta.com",
            audience: "user.vta.com",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(30),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    /// <inheritdoc />
    public async Task<bool> UsernameExistsAsync(string username)
    {
        return await _context.Users.AnyAsync(u => u.Username == username);
    }
}
