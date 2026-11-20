namespace Backendv2.src.API.Routes.artefacts;

using Microsoft.AspNetCore.Routing;
public static class artefactRoutes
{
    public static RouteGroupBuilder MapArtefactRoutes(this RouteGroupBuilder group)
    {

      //gets an artefact for a board 
      // "/users/{id}/boards/{boardid}/images/{ImageId}"
      group.MapGet("/{imageId}", () => "Get artefact" );

      //gets all artefact for a board
      // "/users/{id}/boards/{boardid}/images"
      group.MapGet("/", (int UserId, int BoardId) => "Get all artefacts");
   
      return group;
    }
}