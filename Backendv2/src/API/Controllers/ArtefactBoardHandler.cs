using Backendv2.src.API.DTOs;
using Backendv2.DB.Data;
using Microsoft.EntityFrameworkCore;

namespace Backendv2.src.API.Controllers; 

public class ArtefactBoardHandler
{
    //Returns all artefacts belonging to one board 
    public static async Task<IResult>GetAllArtefactsFromOneBoard(int UserId, int BoardId, VtaDevContext Db)
    {
        var db = await Db.Boards.FindAsync(UserId); 
        if (db is null) {return TypedResults.NotFound();}

        var artefacts = await Db.ArtefactBoards
            .Where(b => b.BoardId == BoardId)
            .Select(b => new ArtefactBoardDto (b))
            .ToListAsync();

        return TypedResults.Ok();
    }

    
    //Creates the grid placement for an artefact on the board 
     public static async Task<IResult> CreateGridForAnArtefactOnABoard(int UserId, int BoardId, int ImageId, int GridX, int GridY, VtaDevContext Db)
    {
        
        var db = await Db.Boards.FindAsync(UserId);
        if (db is null) {return TypedResults.NotFound();}




       
        return TypedResults.Ok();

    }
/*
    //Returns the grid for an artefact on a board
    public static async Task<IResult> GetGridForAnArtefactOnABoard(int UserId, int BoardId, int ImageId, VtaDevContext Db)
    {
        
        var db = await Db.Boards.FindAsync(UserId);
        if (db is null) {return TypedResults.NotFound();}


       
        return TypedResults.Ok();

    }

    //Updates the grid for an artefact 
     public static async Task<IResult> UpdateGridForAnArtefactOnABoard(int UserId, int BoardId, int ImageId, VtaDevContext Db)
    {
        
        var db = await Db.Boards.FindAsync(UserId);
        if (db is null) {return TypedResults.NotFound();}


       
        return TypedResults.Ok();

    }

    */
    public static async Task<IResult> CreatePositionForAnArtefactOnABoard(int BoardId, int ImageId, float PosX, float PosY, VtaDevContext Db)
        {
            


            //var db = await Db.Boards.FindAsync(UserId);
            //if (db is null) {return TypedResults.NotFound();}


        
            return TypedResults.Ok();

        }


    /*
    public static async Task<IResult> GetPositionForAnArtefactOnABoard(int UserId, int BoardId, int ImageId, VtaDevContext Db)
    {
        
        var db = await Db.Boards.FindAsync(UserId);
        if (db is null) {return TypedResults.NotFound();}


       
        return TypedResults.Ok();

    }

    //
    public static async Task<IResult> UpdatePositionForAnArtefactOnABoard(int UserId, int BoardId, int ImageId, VtaDevContext Db)
    {
        
        var db = await Db.Boards.FindAsync(UserId);
        if (db is null) {return TypedResults.NotFound();}


       
        return TypedResults.Ok();

    }

*/


}


