using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;

namespace Backendv2.src.API.Controllers
{

    public class User
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

        var person1 = new User(1,"Jonas","jonas@myass.ai","jonas","Pederson","sidekick");
        var person2 = new User(2,"Lasse","lasse@myass.ai","Lasse","Kreiner","Not sidekick");
        public static GetAll()
        {
            
        }
    
        
    }
}
