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
    public class ArtefactController 
    {
        private readonly VtaDevContext _VtaDevContext;
            
        public ArtefactController(VtaDevContext vtaDevContext)
        {
            _VtaDevContext = vtaDevContext; 
        }


        // Get specific artefact for a board.
        // ab = ArtefactBoards
        // a = Artefacts
        public async Task<ArtefactsDto?> Handle(int imageId, int boardId, int userId)
        {
            return await (
                from ab in _VtaDevContext.ArtefactBoards
                join a in _VtaDevContext.Artefacts
                    on ab.ImageId equals a.ImageId 

                 where ab.BoardId == boardId 
                 && ab.Board.UserId == userId
                 && a.ImageId == imageId

                select new ArtefactsDto 
                {
                    ImageId = a.ImageId,
                    UseCount = a.UseCount,
                }
            ).FirstOrDefaultAsync();
        }

        // Gets all artefacts belonging to a board.
        // ab = ArtefactBoards
        // a = Artefacts
        public async Task<List<ArtefactsDto>> Handle(int boadId, int userId)
        {
            return await (
                from ab in _VtaDevContext.ArtefactBoards
                join a in _VtaDevContext.Artefacts
                    on ab.ImageId equals a.ImageId
                
                where ab.BoardId == boadId
                && ab.Board.UserId == userId

                select new ArtefactsDto 
                {
                    ImageId = a.ImageId,
                    UseCount = a.UseCount,
                }
            ).ToListAsync();
        }
    }
}