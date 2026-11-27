namespace Backendv2.src.API.Routes.artefacts;

using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using VTA.API.Controllers;
using Backendv2.DB.Data;

public static class artefactRoutes
{
    public static RouteGroupBuilder MapArtefactRoutes(this RouteGroupBuilder group)
    {

    // GET /users/{id}/boards/{id}/images/{id}
    // gets an artefact for a board 
      group.MapGet("/{imageId}", async(int imageId, int boardId, VtaDevContext db, ArtefactHandler handler) =>
      { 
        return await handler.GetArtefact(imageId, boardId, db);
      });

    // GET /users/{id}/boards/{id}/images
    // gets all artefact for a board
      group.MapGet("/", async(int imageId, int boardId, VtaDevContext db, ArtefactHandler handler) =>
      {
        var artefacts = await handler.GetAllArtefacts(boardId, imageId, db);
      });

      return group;
    }
}