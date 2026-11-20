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

    // Add the usersettings contex to then db
    private static async Task SeedAsync(string TestDb, UserSetting setting)
    {
        using var db = CreateContext(TestDb);
        db.UserSettings.Add(setting);
        await db.SaveChangesAsync();
    }

    // Test for if a user exists in the database
    [Fact]
    public async Task GetUserSettingsUserExists()
    {
        // Create the in-memory database with data
        var TestDb = Guid.NewGuid().ToString();
        await SeedAsync(TestDb, new UserSetting { UserId = 1, Lightmode = true, Darkmode = false, Language = "da" });

        // Set the db and result up with the function we want to test
        using var Db = CreateContext(TestDb);
        var Result = await UserSettingsHandler.GetUserSettings(1, Db);

        // Check that we get the right code and data back
        var Ok = Assert.IsType<Ok<UserSettingsDto>>(Result);
        Assert.NotNull(Ok.Value);
        Assert.Equal("da", Ok.Value.Language);
    }

    // Test for if a user dont exists in the database
    [Fact]
    public async Task GetUserSettingsUserDontExists()
    {
        // Create the in-memory database
        using var Db = CreateContext(Guid.NewGuid().ToString());

        //result up with the function we want to test and the user 999 (that dont exists)
        var Result = await UserSettingsHandler.GetUserSettings(999, Db);

        // Checks if we get the notfound respones back
        Assert.IsType<NotFound>(Result);
    }

    // Test for if a user dont exists in the database
    [Fact]
    public async Task UpdateUserSettingsUserDontExists()
    {
        // Create the in-memory database
        using var Db = CreateContext(Guid.NewGuid().ToString());

        // Setup the result up with the function we want to test
        var Result = await UserSettingsHandler.UpdateUserSettings(999, new UserSettingsDto { Language = "en" }, Db);

        // checks that we get the 404 notfound respons back
        Assert.IsType<NotFound>(Result);
    }

    // Runs this test 2 times. One with the data (true , true) and one with (false, false)
    [Theory]
    [InlineData(true, true)]
    [InlineData(false, false)]
    public async Task UpdateUserSettingsNotVaild(bool light, bool dark)
    {
        // Create the in-memory database
        var TestDb = Guid.NewGuid().ToString();
        await SeedAsync(TestDb, new UserSetting { UserId = 1, Lightmode = true, Darkmode = false, Language = "en" });
        using var Db = CreateContext(TestDb);

        // Setup the database with the new info
        var Result = await UserSettingsHandler.UpdateUserSettings(
            1, new UserSettingsDto { Lightmode = light, Darkmode = dark }, Db);

        // Checks if we get the 400 respons 
        Assert.IsType<BadRequest<string>>(Result);
    }

    // Test for updates in the database
    [Fact]
    public async Task UpdateUserSettingsInDb()
    {
        // Create the in-memort database
        var TestDb = Guid.NewGuid().ToString();
        await SeedAsync (TestDb, new UserSetting {UserId = 1, Lightmode = true, Darkmode=false, Language = "dk" });
        using var Db = CreateContext(TestDb);

        // Set the result into a new update
        var Result = await UserSettingsHandler.UpdateUserSettings(
            1, new UserSettingsDto {Lightmode = false , Language = "en"}, Db
        );

        // Check if we get the right responsed
        Assert.IsType<NoContent>(Result);

        // Checkes if the fields are updated with the right values
        using var verify = CreateContext(TestDb);
        var saved = await verify.UserSettings.FindAsync([1], TestContext.Current.CancellationToken);
        Assert.NotNull(saved);
        Assert.True(saved.Darkmode);
        Assert.False(saved.Lightmode);
        Assert.Equal("en", saved!.Language);
    }
}   