using VTA.API.DTOs;
using VTA.Data.Models;

namespace VTA.API.Services;

/// <summary>
/// Service for user management — authentication, registration, deletion.
/// Consolidates logic previously duplicated between UsersController and AdminController.
/// </summary>
public interface IUserService
{
    /// <summary>Authenticate a user and return a JWT + userId.</summary>
    /// <returns>Login response, or null if credentials are invalid.</returns>
    Task<UserLoginResponseDTO?> AuthenticateAsync(string username, string password);

    /// <summary>
    /// Register a new user, hash their password, create a default board,
    /// and auto-sign them in.
    /// </summary>
    /// <returns>Login response on success; (null, error) on conflict or failure.</returns>
    Task<(UserLoginResponseDTO? Response, string? Error)> RegisterAsync(UserSignupDTO dto);

    /// <summary>
    /// Create an admin user (used by AdminController).
    /// </summary>
    /// <returns>The created UserGetDTO, or (null, error) on conflict.</returns>
    Task<(UserGetDTO? User, string? Error)> CreateAdminAsync(UserSignupDTO dto);

    /// <summary>
    /// Delete a user and all associated filesystem assets.
    /// </summary>
    /// <returns>True if found and deleted, false if not found.</returns>
    Task<bool> DeleteUserAsync(string userId);

    /// <summary>Generate a JWT for the given user.</summary>
    string GenerateJwt(User user);

    /// <summary>Check whether a username is already taken.</summary>
    Task<bool> UsernameExistsAsync(string username);
}
