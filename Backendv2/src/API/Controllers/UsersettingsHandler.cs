using Backendv2.DB.Data;
using Backendv2.src.API.DTOs.userSettingsDto;

namespace  Backendv2.src.API.Controllers.UserSettingsHandler;


public class UserSettingsHandler
{
    public static async Task<IResult> GetUserSettings(int Id, VtaDevContext Db)
    {
        // Retun the user settings if the user is found in the database if not then send 404
        return await Db.UserSettings.FindAsync(Id)
            is UserSetting UserSetting
                ? TypedResults.Ok(new UserSettingsDto(UserSetting))
                : TypedResults.NotFound();
    }

    public static async Task<IResult> UpdateUserSettings(int Id, UserSettingsDto InputUsersetting, VtaDevContext Db)
    {
        // Find the user in the database and make it a variable
        var db = await Db.UserSettings.FindAsync(Id); 

        // If the user is not in the database then return 404
        if (db is null) {return TypedResults.NotFound();}

        // Both true/false in the same request is contradictory, so reject it
        if (InputUsersetting.Lightmode is true && InputUsersetting.Darkmode is true || InputUsersetting.Lightmode is false && InputUsersetting.Darkmode is false)
        {
            return TypedResults.BadRequest("Lightmode and Darkmode cannot both be true or both be false.");
        }

        // Take the input and update only the fields that was given 
        if (InputUsersetting.Contrast is not null) { db.Contrast = InputUsersetting.Contrast.Value; }
        if (InputUsersetting.Lightmode is not null) { db.Lightmode = InputUsersetting.Lightmode.Value; }
        if (InputUsersetting.Darkmode is not null) { db.Darkmode = InputUsersetting.Darkmode.Value; }
        if (InputUsersetting.Language is not null) { db.Language = InputUsersetting.Language; }
        if (InputUsersetting.SentenceBar is not null) { db.SentenceBar = InputUsersetting.SentenceBar.Value; }

        // Turning one mode on turns the other off, and turning one off turns the other on
        if (InputUsersetting.Lightmode is true) { db.Darkmode = false; }
        else if (InputUsersetting.Darkmode is true) { db.Lightmode = false; }
        else if (InputUsersetting.Lightmode is false) { db.Darkmode = true; }
        else if (InputUsersetting.Darkmode is false) { db.Lightmode = true; }

        // Save the input into the database
        await Db.SaveChangesAsync();

        // Retun 204 
        return TypedResults.NoContent();
    }
}