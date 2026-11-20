using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data;
using Backendv2.src.API.Routes.DTOs.UserDto;
using Backendv2.src.API.Routes.DTOs.userSettingsDto;

namespace Backendv2.src.API.Controllers
{
    public class UserHandler
    {
        public static async Task<IResult> GetAllUsers(HttpClient Core)
        {
            var Users = await Core.GetAllUsersAsync();  //This was made before Core, so this propably needs to be changed
            return TypedResults.Ok(Users);
        }


        public static async Task<IResult> GetUserById(int Id, HttpClient Core)
        {
            return await Core.GetUserAsync(Id)  //This was made before Core, so this propably needs to be changed
                is UserDto User
                    ? TypedResults.Ok(User)
                    : TypedResults.NotFound();
        }

        public static async Task<IResult> CreateUser(UserDto UserDto, HttpClient Core)
        {
            var CreatedUser = await Core.CreateUserAsync(UserDto);  //This was made before Core, so this propably needs to be changed

            return TypedResults.Created($"/Users/{CreatedUser.Id}", CreatedUser);

        }

        public static async Task<IResult> UpdateUser(int Id, UserDto UserDto, HttpClient Core)
        {
            return await Core.UpdateUserAsync(Id, UserDto)  //This was made before Core, so this propably needs to be changed
                ? TypedResults.NoContent()
                : TypedResults.NotFound();
        }

        public static async Task<IResult> DeleteUser(int Id, HttpClient Core)
        {
            return await Core.DeleteUserAsync(Id)  //This was made before Core, so this propably needs to be changed
                ? TypedResults.NoContent()
                : TypedResults.NotFound();
        }

        public static async Task<IResult> ChangeUserPassword(int Id, UserDto UserDto, HttpClient Core)
        {
            return await Core.ChangeUserPasswordAsync(Id, UserDto)  //This was made before Core, so this propably needs to be changed
                ? TypedResults.NoContent()
                : TypedResults.NotFound();
        }

        public static async Task<IResult> GetUserSettings(int Id, VtaDevContext Db)
        {
            return await Db.UserSettings.FindAsync(Id)
                is UserSetting UserSetting
                    ? TypedResults.Ok(UserSetting)
                    :TypedResults.NotFound();
        }

        public static async Task<IResult> UpdateUserSettings(int Id, UserSettingsDto UserSettingsDto, VtaDevContext Db)
        
        {
            var UserSetting = await Db.UserSettings.FindAsync(Id);
            if (UserSetting is null) return TypedResults.NotFound();

            UserSetting.Lightmode = UserSettingsDto.Lightmode;
            UserSetting.Darkmode = UserSettingsDto.Darkmode;
            UserSetting.Contrast = UserSettingsDto.Contrast;
            UserSetting.Language = UserSettingsDto.Language;
            UserSetting.SentenceBar = UserSettingsDto.SentenceBar;

            await Db.SaveChangesAsync();
            return TypedResults.NoContent();
        }

    }
}
