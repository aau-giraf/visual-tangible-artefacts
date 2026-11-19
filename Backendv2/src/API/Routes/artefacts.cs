namespace Backendv2.src.API.Routes.artefacts;

using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using VTA.API.Controllers;
public static class artefactRoutes
{
    public static RouteGroupBuilder MapArtefactRoutes(this RouteGroupBuilder group)
    {

    // GET /users/{id}/boards/{id}/images/{id}
    // gets an artefact for a board 
      group.MapGet("/{imageId}", async(int imageId, int boardId, int userId, ArtefactHandler handler) =>
      {
        var artefact = await handler.GetArtefact(imageId, boardId, userId);
        return artefact is null ? Results.NotFound() : Results.Ok(artefact); 
      });

    // GET /users/{id}/boards/{id}/images
    // gets all artefact for a board
      group.MapGet("/", async(int imageId, int boardId, int userId, ArtefactHandler handler) =>
      {
        var artefacts = await handler.GetAllArtefacts(boardId, userId);
        return artefacts is null ? Results.NotFound() : Results.Ok(artefacts);
      });

      return group;
    }
}