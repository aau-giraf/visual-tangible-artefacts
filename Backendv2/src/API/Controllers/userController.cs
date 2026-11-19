using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data;
using Backendv2.src.API.Routes.DTOs.UserDto;

namespace Backendv2.src.API.Controllers
{
    public class UserController
    {
        public static async Task<IResult> GetAllUsers(VtaDevContext Db)
        {
            return TypedResults.Ok(await Db.Users.Select(x => new UserDto(x)).ToArrayAsync());
        }


        public static async Task<IResult> GetUserById(int Id, VtaDevContext Db)
        {
            return await Db.Users.FindAsync(Id)
                is User User
                    ? TypedResults.Ok(new UserDto(User))
                    : TypedResults.NotFound();
        }

        public static async Task<IResult> CreateUser(UserDto UserDto, VtaDevContext Db)
        {
            var User = new User
            {
                Id = UserDto.Id
            };

            Db.Users.Add(User);
            await Db.SaveChangesAsync();

            UserDto = new UserDto(User);

            return TypedResults.Created($"/Users/{User.Id}", UserDto);

        }

        public static async Task<IResult> UpdateUser(int Id, UserDto UserDto, VtaDevContext Db)
        {
            var User = await Db.Users.FindAsync(Id);

            if (User is null) return TypedResults.NotFound();

            //User.XXX = UserDto.XXX

            await Db.SaveChangesAsync();

            return TypedResults.NoContent();
        }

        public static async Task<IResult> DeleteUser(int Id, VtaDevContext Db)
        {
            if (await Db.Users.FindAsync(Id) is User User)
            {
                Db.Users.Remove(User);
                await Db.SaveChangesAsync();
                return TypedResults.NoContent();
            }
            return TypedResults.NotFound();
        }

    }
}
