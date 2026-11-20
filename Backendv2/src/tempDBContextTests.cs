using System.Reflection;
using Backendv2.DB.Data;
using Backendv2.DB.Data.Models.DummyCoreModels;
using Backendv2.DB.Data.Models.VTAModels;
using Microsoft.EntityFrameworkCore;
using System.Reflection;
using Microsoft.AspNetCore.Routing;
using Backendv2.src.API.DTOs.DummyCore;
using Backendv2.src.API.Handlers.DummyCoreHandler;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Backendv2.src.API.Routes;

// Temporary smoke tests. Delete this file (and the call in Program.cs) when done.
public static class TempDbTestRoutes
{
    public static RouteGroupBuilder MapDbTestRoutes(this RouteGroupBuilder group)
    {
        group.MapGet("/vta", VtaTest);
        group.MapGet("/dummycore", DummyCoreTest);
        group.MapGet("/dummycoreusers", DummyCoreUsersTest);

        group.MapGet("/all", async (VtaContext vta, DummyCoreContext dummy) =>
        {
            var vtaOk = Passed(await VtaTest(vta));
            var dummyOk = Passed(await DummyCoreTest(dummy));
            var usersOk = Passed(await DummyCoreUsersTest(dummy));
            var allOk = vtaOk && dummyOk && usersOk;

            return Results.Json(new
            {
                result = allOk ? "ALL PASSED" : "FAILED",
                vta = vtaOk ? "passed" : "failed",
                dummycore = dummyOk ? "passed" : "failed",
                dummycoreusers = usersOk ? "passed" : "failed"
            }, statusCode: allOk ? 200 : 500);
        });

        return group;
    }

    //////////////////////////////////////////////////////////////////////////////////////////
    /// DummyCore smoke test: create, read, update, delete a few entities in a transaction ///
    //////////////////////////////////////////////////////////////////////////////////////////
    /// <summary>
    /// Performs a smoke test on the DummyCore context by creating, reading, updating, and deleting a few entities in a transaction.
    /// </summary>
    /// <param name="db"> The DummyCore context. </param>
    /// <returns> A task representing the asynchronous operation.</returns>
    private static async Task<IResult> DummyCoreTest(DummyCoreContext db)
    {
        var log = new List<string>();
        void Step(string msg) { Console.WriteLine(msg); log.Add(msg); }

        await using var tx = await db.Database.BeginTransactionAsync();

        try
        {
            Step($"Can connect: {await db.Database.CanConnectAsync()}");

            // Read check of every mapped table
            Step($"Citizens: {await db.Citizens.CountAsync()}");
            Step($"Classes: {await db.Classes.CountAsync()}");
            Step($"Images: {await db.Images.CountAsync()}");
            Step($"NonCitizens: {await db.NonCitizens.CountAsync()}");
            Step($"Organizations: {await db.Organizations.CountAsync()}");
            Step($"Users: {await db.Users.CountAsync()}");
            Step($"UserRoles: {await db.UserRoles.CountAsync()}");

            // Organization (id from organization_id_seq)
            var org = new Organization { Name = "smoke test org" };
            db.Add(org);
            await db.SaveChangesAsync();
            Step($"Organization created: {org.Id}");

            // Class -> Organization
            var cls = new Class { Name = "smoke test class", OrganizationId = org.Id };
            db.Add(cls);
            await db.SaveChangesAsync();
            Step($"Class created: {cls.Id}");

            // Two users: one will be the citizen, one the non-citizen
            var citizenUser = new User { FirstName = "Test", LastName = "Citizen", UserName = "smoke_citizen", Password = "x" };
            var guardianUser = new User { FirstName = "Test", LastName = "Guardian", UserName = "smoke_guardian", Password = "x" };
            db.AddRange(citizenUser, guardianUser);
            await db.SaveChangesAsync();
            Step($"Users created: {citizenUser.Id}, {guardianUser.Id}");

            // Citizen / NonCitizen share their PK with user.id
            var citizen = new Citizen { Id = citizenUser.Id, ClassId = cls.Id };
            var nonCitizen = new NonCitizen { Id = guardianUser.Id, Email = "smoke@test.local" };
            db.AddRange(citizen, nonCitizen);
            await db.SaveChangesAsync();
            Step("Citizen and NonCitizen created");

            // UserRole (composite key: nonCitizenId + organizationId + role)
            var role = new UserRole { NonCitizenId = nonCitizen.Id, OrganizationId = org.Id, Role = "admin" };
            db.Add(role);
            await db.SaveChangesAsync();
            Step("UserRole created");

            // Image -> Citizen + Organization (createdAt left to the DB default)
            var image = new Image
            {
                Name = "smoke image",
                CitizenId = citizen.Id,
                OrganizationId = org.Id,
                Path = "/smoke/test.png",
                StorageKey = "smoke-key",
                FileName = "test.png",
                FileType = "image/png",
                SizeBytes = 123
            };
            db.Add(image);
            await db.SaveChangesAsync();
            Step($"Image created: {image.Id}");

            // Read back
            var loaded = await db.Images
                .Where(i => i.Id == image.Id)
                .Select(i => new { i.Id, i.FileName, i.CreatedAt })
                .FirstAsync();
            Step($"Image read back: {loaded.Id} / {loaded.FileName} / createdAt {loaded.CreatedAt}");

            // Update
            org.Name = "renamed smoke org";
            await db.SaveChangesAsync();
            Step("Organization renamed");

            // Delete in FK order
            db.RemoveRange(image, role, citizen, nonCitizen);
            await db.SaveChangesAsync();
            db.RemoveRange(citizenUser, guardianUser, cls);
            await db.SaveChangesAsync();
            db.Remove(org);
            await db.SaveChangesAsync();
            Step("Deleted everything");

            await tx.RollbackAsync();
            Step("All steps passed (transaction rolled back)");
            return Results.Ok(log);
        }
        catch (Exception ex)
        {
            Step($"FAILED: {ex.GetBaseException().Message}");
            await tx.RollbackAsync();
            Step("Transaction rolled back");
            return Results.Problem(string.Join("\n", log));
        }
    }
    private static async Task<IResult> DummyCoreUsersTest(DummyCoreContext db, CancellationToken ct = default)
    {
        var log = new List<string>();
        void Step(string msg) { Console.WriteLine(msg); log.Add(msg); }
        void Check(bool ok, string msg)
        {
            if (!ok) throw new InvalidOperationException(msg);
            Step($"OK: {msg}");
        }

        await using var tx = await db.Database.BeginTransactionAsync(ct);

        try
        {
            // Two organizations: org1 gets the lower id, so it must win the role pick
            var org1 = new Organization { Name = "smoke org 1" };
            var org2 = new Organization { Name = "smoke org 2" };
            db.AddRange(org1, org2);
            await db.SaveChangesAsync(ct);

            var cls = new Class { Name = "smoke class", OrganizationId = org1.Id };
            db.Add(cls);
            await db.SaveChangesAsync(ct);

            var citizenUser = new User { FirstName = "Test", LastName = "Citizen", UserName = "smoke_user_citizen", Password = "x" };
            var teacherUser = new User { FirstName = "Test", LastName = "Teacher", UserName = "smoke_user_teacher", Password = "x" };
            db.AddRange(citizenUser, teacherUser);
            await db.SaveChangesAsync(ct);

            db.Add(new Citizen { Id = citizenUser.Id, ClassId = cls.Id });
            db.Add(new NonCitizen { Id = teacherUser.Id, Email = "teacher@smoke.local" });
            await db.SaveChangesAsync(ct);

            // org2 role is added first on purpose: the result must not depend on insert order
            db.Add(new UserRole { NonCitizenId = teacherUser.Id, OrganizationId = org2.Id, Role = "parent" });
            db.Add(new UserRole { NonCitizenId = teacherUser.Id, OrganizationId = org1.Id, Role = "teacher" });
            await db.SaveChangesAsync(ct);
            Step("Seed data created");

            // GetById: citizen
            var citizenResult = await DummyCoreUserHandler.GetById(citizenUser.Id, db, ct);
            Check(citizenResult.Result is Ok<UserDetailsDto>, "GetById citizen returns 200");
            var citizenDto = ((Ok<UserDetailsDto>)citizenResult.Result).Value!;
            Check(citizenDto.Role == "citizen", "citizen role is 'citizen'");
            Check(citizenDto.Email is null, "citizen email is null");

            // GetById: non-citizen with two roles
            var teacherResult = await DummyCoreUserHandler.GetById(teacherUser.Id, db, ct);
            Check(teacherResult.Result is Ok<UserDetailsDto>, "GetById teacher returns 200");
            var teacherDto = ((Ok<UserDetailsDto>)teacherResult.Result).Value!;
            Check(teacherDto.Email == "teacher@smoke.local", "teacher email comes from NonCitizen");
            Check(teacherDto.Role == "teacher", "teacher role is the one from the lowest organization id");

            // GetById: missing user
            var missingResult = await DummyCoreUserHandler.GetById(-1, db, ct);
            Check(missingResult.Result is NotFound, "GetById unknown id returns 404");

            // GetAll
            var all = (await DummyCoreUserHandler.GetAll(db, ct)).Value!;
            var ids = all.Select(u => u.Id).ToList();
            Check(ids.Contains(citizenUser.Id) && ids.Contains(teacherUser.Id), "GetAll contains both seeded users");
            Check(ids.SequenceEqual(ids.OrderBy(i => i)), "GetAll is ordered by id");

            // CreateUser
            var createDto = new CreateUserDto(
                "smoke_created_user",
                "test_password",
                null,
                "Created",
                "User",
                "citizen",
                null,
                cls.Id
            );

            var createResult = await DummyCoreUserHandler.CreateUser(createDto, db, ct);

            Check(createResult.Result is Created<UserDetailsDto>, "CreateUser returns 201");

            var createdUser = ((Created<UserDetailsDto>)createResult.Result).Value!;

            Check(createdUser.Id > 0, "CreateUser assigns an id");
            Check(createdUser.UserName == createDto.UserName, "CreateUser returns correct username");
            Check(createdUser.Role == "citizen", "CreateUser returns correct role");

            // Verify created user can be retrieved
            var createdUserResult = await DummyCoreUserHandler.GetById(createdUser.Id, db, ct);

            Check(createdUserResult.Result is Ok<UserDetailsDto>, "Created user can be retrieved");

            await tx.RollbackAsync(ct);
            Step("All steps passed (transaction rolled back)");
            return Results.Ok(log);
        }
        catch (Exception ex)
        {
            Step($"FAILED: {ex.GetBaseException().Message}");
            await tx.RollbackAsync(ct);
            Step("Transaction rolled back");
            return Results.Problem(string.Join("\n", log));
        }
    }




    ////////////////////////////////////////////////////////////
    /// VTA smoke test: create, read, update, delete a Board ///
    ////////////////////////////////////////////////////////////
    /// <summary>
    /// Performs a smoke test on the VTA context by creating, reading, updating, and deleting a board.
    /// </summary>
    /// <param name="db">The VTA context.</param>
    /// <returns>A task representing the asynchronous operation.</returns>
    private static async Task<IResult> VtaTest(VtaContext db)
    {
        var log = new List<string>();
        void Step(string msg) { Console.WriteLine(msg); log.Add(msg); }

        try
        {
            Step($"Can connect: {await db.Database.CanConnectAsync()}");

            // Create (Id is ValueGeneratedNever, so we set it ourselves)
            Step("Inserting a new board");
            var board = new Board { Id = 9999, Name = "test board", UserId = 1 };
            db.Add(board);
            await db.SaveChangesAsync();

            // Read
            Step("Querying for the board");
            var found = await db.Boards
                .OrderBy(b => b.Id)
                .FirstAsync(b => b.Id == 9999);
            Step($"Found board: {found.Id} / {found.Name}");

            // Update
            Step("Updating the board name");
            found.Name = "renamed test board";
            await db.SaveChangesAsync();

            // Delete
            Step("Deleting the board");
            db.Remove(found);
            await db.SaveChangesAsync();

            Step("All steps passed");
            return Results.Ok(log);
        }
        catch (Exception ex)
        {
            Step($"FAILED: {ex.GetBaseException().Message}");
            return Results.Problem(string.Join("\n", log));
        }
    }

    public static WebApplication UseTempDebug(this WebApplication app)
    {
        Console.WriteLine($"Conn string: {app.Configuration.GetConnectionString("VTAConnectionString") ?? "NOT FOUND"}");
        Console.WriteLine($"Dummy conn string: {app.Configuration.GetConnectionString("DummyCoreConnectionString") ?? "NOT FOUND"}");


        var assemblyPath = Assembly.GetExecutingAssembly().Location;

        Console.WriteLine($"[DEBUG] PID: {Environment.ProcessId}");
        Console.WriteLine($"[DEBUG] Assembly: {assemblyPath}");
        Console.WriteLine($"[DEBUG] Built: {File.GetLastWriteTime(assemblyPath)}");
        Console.WriteLine($"[DEBUG] Started: {DateTime.Now}");

        // Log every request that reaches this app, with the final status code
        app.Use(async (ctx, next) =>
        {
            Console.WriteLine($"[REQ] --> {ctx.Request.Method} {ctx.Request.Path}");
            await next();
            Console.WriteLine($"[REQ] <-- {ctx.Response.StatusCode} {ctx.Request.Path}");
        });

        // Dump every registered route once the app is up (runs after all mappings exist)
        app.Lifetime.ApplicationStarted.Register(() =>
        {
            Console.WriteLine("[DEBUG] Registered endpoints:");
            foreach (var ds in ((IEndpointRouteBuilder)app).DataSources)
                foreach (var e in ds.Endpoints.OfType<RouteEndpoint>())
                    Console.WriteLine($"[DEBUG]   {e.RoutePattern.RawText}");
        });

        // Trivial endpoint with no DB involved
        app.MapGet("/ping", () => "pong");

        return app;
    }

    private static bool Passed(IResult r) => r is IStatusCodeHttpResult { StatusCode: >= 200 and < 300 };
}