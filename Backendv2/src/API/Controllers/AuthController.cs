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

    private class UserInfo
    {
       public string Username { get; set; }
       public string Password { get; set; }


        private UserInfo(string username, string password)
        {
            Username = username;
            Password = password;
        }
    }

    // TODO: needs user information from FK
    public async Task<IResult> Login(UserInfo userInfo, UserManager<IdentityUser> userManager, SignInManager<IdentityUser> signInManager) 
    {
        
        var user = await userManager.FindByIdAsync(
            userInfo.Username
            );
        
        if(user == null)
        {
            return Results.Unauthorized();
        }

        var password = await signInManager.CheckPasswordSignInAsync(
            user,
            userInfo.Password,
            lockoutOnFailure: true
        );

        if(!password.Succeeded)
        {
            return Results.Unauthorized();
        }


        // TODO: generate JWT
        // var token = jwt.GenerateToken(user);

        return Results.Ok("Verified!!!");
        
        
    }
    
}


