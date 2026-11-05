namespace Backendv2.src.API.Routes.artefacts;

using Microsoft.AspNetCore.Routing;
public static class artefactRoutes
{
    public static RouteGroupBuilder MapArtefactRoutes(this RouteGroupBuilder group)
    {

    //gets an artefact for a board 

     group.MapGet("/{imageId}", () => "Get artefact" );
      
      //GetArtefact, add this after the method is made

     //gets all artefact for a board

     group.MapGet("/", () => "Get all artefacts");

     //GetAllArtefacts, add this after the method is made

    // Implement GetArtefact here

    // Implement GetAllArtefacts here
   
      return group;
    }
}