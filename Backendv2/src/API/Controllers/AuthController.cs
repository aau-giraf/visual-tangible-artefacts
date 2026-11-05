using System.IO.Pipelines;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.VisualBasic;


namespace Backendv2.src.API.Controllers.AuthController;

public class AuthController
{
    //JWT -> json web tokens
    //UserName userId
    //Password

    // TODO: DTO needs to be created.
    public static async Task<IResult> Login(UserDto userDto, UserManager<IdentityUser> userManager, SignInManager<IdentityUser> signInManager) 
    {

        var user = await userManager.FindByIdAsync(
            userDto.Username
            );
        
        if(user == null)
        {
            return Results.Unauthorized();
        }

        var password = await signInManager.CheckPasswordSignInAsync(
            user,
            userDto.Password,
            lockoutOnFailure: true
        );

        if(!password)
        {
            return Results.Unauthorized();
        }


        // TODO: generate JWT

        return Results.Ok("Verified!!!");
        
        
    }
    
}


