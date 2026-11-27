using System;
using System.Collections.Generic;
using System.Data.Common;
using System.Text;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;

using Backendv2.src.API.Routes.DTOs.ArtefactsDto;
using System.Runtime.CompilerServices;
using Backendv2.DB.Data;


namespace VTA.API.Controllers
{
    public class ArtefactHandler
    {
        
        // Get specific artefact for a board.
        public async Task<IResult> GetArtefact(int imageId, int boardId, VtaDevContext db)
        {
            
            var artefact = await db.Artefacts.FindAsync(imageId);
            var artefactBoard = await db.ArtefactBoards.FindAsync(boardId);

            if (artefact != null && artefactBoard != null && (artefact.ImageId == artefactBoard.ImageId)){

                return TypedResults.Ok(new ArtefactsDto(artefact));
            } else {
                return TypedResults.NotFound();
            }
        }

        // Gets all artefacts belonging to a board.
        public async Task<IResult> GetAllArtefacts(int boardId, int imageId, VtaDevContext db)
        {
            var artefactBoard = await db.ArtefactBoards.FindAsync(boardId);
            if (artefactBoard != null)
            {
               var artefacts = await db.Artefacts
                .Where (artefact => artefactBoard.ImageId == imageId)
                .Select (artefact => new ArtefactsDto(artefact))
                .ToListAsync(); 

                return TypedResults.Ok(artefacts);
            } else {
                return TypedResults.NotFound();
            }
        }
    }
}