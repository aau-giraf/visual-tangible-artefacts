using Backendv2.src.API.Controllers;

namespace Backendv2.src.API.Routes
{
    public static class helloWorldRoutes
    {
        public static void MapHelloRouter(this IEndpointRouteBuilder app)
        {

            app.MapGet("/hello", helloWorldHandler.SayHello);

        }

        public static RouteGroupBuilder MapHelloRoutes(this RouteGroupBuilder group)
        {
            group.MapGet("/hello", helloWorldHandler.SayHello);
            return group;
        }
    }
}
