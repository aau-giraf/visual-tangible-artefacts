using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Backendv2.src.API.Controllers
{

    public class User (int Id, string UserName, string Email, string FirstName, string LastName, string Role)
    {
        public int Id {get; set;}
        public string UserName {get; set;}
        public string Email {get; set;}
        public string FirstName {get; set;}
        public string LastName {get; set;}
        public string Role {get; set;}
    };


    public class UserController
    {
        public static IResult GetAll(User person1, User person2)
        {
            return TypedResults.Ok(new List<User> {person1, person2});
        }
    }
}
