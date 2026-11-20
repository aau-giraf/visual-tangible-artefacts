using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data.Models.DummyCoreModels;
using Backendv2.src.API.DTOs.DummyCore;

namespace Backendv2.src.API.Handlers.DummyCoreHandler;

public static class DummyCoreUserHandler
{
    /// <summary>
    /// Retrieves the user with the specified identifier.
    /// </summary>
    /// <param name="userId">The identifier of the user to retrieve.</param>
    /// <param name="db">The database context used to access user records.</param>
    /// <param name="ct">A cancellation token that cancels the retrieval operation.</param>
    /// <returns>The matching user details, or a not-found result when no user has the specified identifier.</returns>
    public static async Task<Results<Ok<UserDetailsDto>, NotFound>> GetById(int userId, DummyCoreContext db, CancellationToken ct)
    {
        // Retrieve the user with the specified identifier, including their associated NonCitizen and Citizen data
        var user = await ProjectUsers(db.Users.Where(u => u.Id == userId))
            .FirstOrDefaultAsync(ct);

        return user is null ? TypedResults.NotFound() : TypedResults.Ok(user);
    }

    /// <summary>
    /// Retrieves all users ordered by identifier.
    /// </summary>
    /// <param name="db">The database context containing the users.</param>
    /// <param name="ct">A token that cancels the operation.</param>
    /// <returns>An HTTP 200 response containing all user details.</returns>
    public static async Task<Ok<List<UserDetailsDto>>> GetAll(DummyCoreContext db, CancellationToken ct)
    {
        // Retrieve all users, including their associated NonCitizen and Citizen data, ordered by Id
        var users = await ProjectUsers(db.Users.OrderBy(u => u.Id))
            .ToListAsync(ct);

        return TypedResults.Ok(users);
    }

    /// <summary>
    /// Creates a new user and its associated citizen or non-citizen profile.
    /// </summary>
    /// <param name="body">The user details and role-specific identifiers used to create the user.</param>
    /// <param name="db">The database context used to validate and persist the user.</param>
    /// <param name="ct">A token that cancels the create operation.</param>
    /// <returns>A response containing the created user details, or a bad request or conflict describing why the user could not
    /// be created.</returns>
    public static async Task<Results<Created<UserDetailsDto>, BadRequest<string>, Conflict<string>>> CreateUser(CreateUserDto body, DummyCoreContext db, CancellationToken ct)
    {
        // Validation
        // Check for required fields
        if (string.IsNullOrWhiteSpace(body.UserName) || string.IsNullOrWhiteSpace(body.Password))
            return TypedResults.BadRequest("UserName and Password are required.");

        // Check for required role and associated identifiers
        if (string.IsNullOrWhiteSpace(body.Role))
            return TypedResults.BadRequest("Role is required.");

        // Check for uniqueness of UserName
        if (await db.Users.AnyAsync(u => u.UserName == body.UserName, ct))
            return TypedResults.Conflict("UserName is already taken.");

        // Check for existence of ClassId or OrganizationId based on role
        if (body.Role == "citizen")
        {
            if (body.ClassId is null || !await db.Classes.AnyAsync(c => c.Id == body.ClassId, ct))
                return TypedResults.BadRequest("A citizen needs a valid ClassId.");
        }
        else
        {
            if (body.OrganizationId is null ||
                !await db.Organizations.AnyAsync(o => o.Id == body.OrganizationId, ct))
                return TypedResults.BadRequest("A non-citizen needs a valid OrganizationId.");
        }

        // Creation
        // Map the request DTO to a User entity and its associated Citizen or NonCitizen entity
        var user = MapToUser(body);

        // Add the new user to the database and save changes
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        // Return the created user details in the response
        var created = await ProjectUsers(db.Users.Where(u => u.Id == user.Id))
            .FirstAsync(ct);

        // Return a 201 Created response with the location of the new user and the user details
        return TypedResults.Created($"/dummycore/get/userId={user.Id}", created);
    }




    ////////////////////////////////////////////////////
    /// Helper Functions: ProjectUsers and MapToUser ///
    ////////////////////////////////////////////////////


    /// <summary>
    /// Projects users into user detail DTOs without tracking the source entities.
    /// </summary>
    /// <param name="users">The users to project.</param>
    /// <returns>An untracked query of user detail DTOs.</returns>
    private static IQueryable<UserDetailsDto> ProjectUsers(IQueryable<User> users)
    {
        // Project the users into UserDetailsDto objects, including their associated NonCitizen and Citizen data
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

    /// <summary>
    /// Maps a user creation DTO to a user entity, including the appropriate citizen or non-citizen profile.
    /// </summary>
    /// <remarks> Citizen users receive a citizen profile. All other roles receive a non-citizen profile with
    /// an organization role. </remarks>
    /// <param name="body"> The user creation data to map. </param>
    /// <returns> A user entity populated from the supplied creation data. </returns>
    private static User MapToUser(CreateUserDto body)
    {
        // Create a new User entity and populate its properties from the request DTO
        var user = new User
        {
            UserName = body.UserName,
            Password = body.Password,
            FirstName = body.FirstName,
            LastName = body.LastName
        };

        // Assign the appropriate profile based on the user's role
        if (body.Role == "citizen")
        {
            user.Citizen = new Citizen
            {
                ClassId = body.ClassId!.Value
            };
        }
        else
        {
            user.NonCitizen = new NonCitizen
            {
                Email = body.Email,
                UserRoles =
            {
                new UserRole
                {
                    OrganizationId = body.OrganizationId!.Value,
                    Role = body.Role
                }
            }
            };
        }

        return user;
    }
}