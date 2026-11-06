using Microsoft.AspNetCore.Http.HttpResults;


namespace Backendv2.src.API.Controllers
{
    public class helloWorldHandler
    {
        public static Ok<string> SayHello()
        {
            return TypedResults.Ok("Hello world");
        }
    }
}
