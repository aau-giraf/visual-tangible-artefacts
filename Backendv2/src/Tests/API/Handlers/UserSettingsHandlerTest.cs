using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Backendv2.src.API.DTOs.userSettingsDto;
using Backendv2.src.API.Controllers.UserSettingsHandler;
using Xunit;
using Backendv2.DB.Data;

namespace TestProject.API.Handlers;

public class UserSettingsHandlerTests
{
    // Each test gets its own isolated in-memory database
    private static VtaDevContext CreateContext(string TestDb)
    {
        var options = new DbContextOptionsBuilder<VtaDevContext>()
            .UseInMemoryDatabase(TestDb)
            .Options;
        return new VtaDevContext(options);
    }

    private static async Task SeedAsync(string TestDb, UserSetting setting)
    {
        using var db = CreateContext(TestDb);
        db.UserSettings.Add(setting);
        await db.SaveChangesAsync();
    }


    [Fact]
    public async Task GetUserSettingsUserExists()
    {
        var TestDb = Guid.NewGuid().ToString();
        await SeedAsync(TestDb, new UserSetting { UserId = 1, Lightmode = true, Darkmode = false, Language = "da" });

        using var Db = CreateContext(TestDb);
        var Result = await UserSettingsHandler.GetUserSettings(1, Db);

        var ok = Assert.IsType<Ok<UserSettingsDto>>(Result);
        Assert.NotNull(ok.Value);
        Assert.Equal("da", ok.Value.Language);
    }

    [Fact]
    public async Task GetUserSettingsUserDontExists()
    {
        // Create the in-memary database
        using var db = CreateContext(Guid.NewGuid().ToString());

        var result = await UserSettingsHandler.GetUserSettings(999, db);

        Assert.IsType<NotFound>(result);
    }
}   
