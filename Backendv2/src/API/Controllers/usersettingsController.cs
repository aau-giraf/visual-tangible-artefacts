using Backendv2.DB.Data;
using Backendv2.src.API.DTOs.userSettingsDto;

namespace  Backendv2.src.API.Controllers.usersettingsController;


public class UserSettingsController
{
    public static async Task<IResult> GetUserSettings(int Id, VtaDevContext Db)
    {
        return await Db.UserSettings.FindAsync(Id)
            is UserSetting UserSetting
                ? TypedResults.Ok(new UserSettingsDto(UserSetting))
                : TypedResults.NotFound();
    }

    public static async Task<IResult> updateUserSettings(int Id, UserSettingsDto InputUsersetting, VtaDevContext Db)
    {
       var db = await Db.UserSettings.FindAsync(Id); 

        if (db is null) {return TypedResults.NotFound();}

        // if (InputUsersetting.Contrast is not true || false) {db = InputUsersetting.Contrast}

        await Db.SaveChangesAsync();

        return TypedResults.NoContent();
    }
}