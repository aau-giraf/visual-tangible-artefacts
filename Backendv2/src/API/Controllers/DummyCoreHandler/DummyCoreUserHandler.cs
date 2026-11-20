using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data.Models.DummyCoreModels;
using Backendv2.src.API.DTOs.DummyCore;

namespace Backendv2.src.API.Handlers.DummyCoreHandler;

public static class DummyCoreUserHandler
{
    public static async Task<Results<Ok<UserDetailsDto>, NotFound>> GetById(
        int userId, DummyCoreContext db, CancellationToken ct)
    {
        var user = await ProjectUsers(db.Users.Where(u => u.Id == userId))
            .FirstOrDefaultAsync(ct);

        return user is null ? TypedResults.NotFound() : TypedResults.Ok(user);
    }

    public static async Task<Ok<List<UserDetailsDto>>> GetAll(
        DummyCoreContext db,
        CancellationToken ct)
    {
        var users = await ProjectUsers(db.Users.OrderBy(u => u.Id))
            .ToListAsync(ct);

        return TypedResults.Ok(users);
    }

    private static IQueryable<UserDetailsDto> ProjectUsers(IQueryable<User> users)
    {
        return users.AsNoTracking().Select(u => new UserDetailsDto(
            u.Id,
            u.UserName,
            u.NonCitizen != null ? u.NonCitizen.Email : null,
            u.FirstName,
            u.LastName,
            u.Citizen != null
                ? "citizen"
                : u.NonCitizen!.UserRoles
                    .OrderBy(r => r.OrganizationId)
                    .Select(r => r.Role)
                    .FirstOrDefault()));
    }
}