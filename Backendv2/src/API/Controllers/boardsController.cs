
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data;
using Backendv2.src.API.DTOs.BoardsDto;

namespace  Backendv2.src.API.Controllers.boardsController;


public class boardsController
{
  //Finds a board then sees if the board exists and belongs to the selected user.
    public static async Task<IResult> getBoard( int id, int boardId, VtaDevContext db)
    {

        var board = await db.Boards.FindAsync(boardId);

         if (board != null && board.UserId == id )
        {
            return TypedResults.Ok(new BoardsDto(board)); 
            
        }
         else
        {
           return TypedResults.NotFound(); 
        }
    }

 // Finds all the boards belonging to a selected user, then returns ok if the user has no board then returns an empty list.
   public static async Task<IResult> getAllBoards(int id, VtaDevContext db)
       
    {
        var boards = await db.Boards
              .Where (board => board.UserId == id)
              .Select (board => new BoardsDto (board))
              .ToListAsync();
              
        return TypedResults.Ok(boards);
    }


// Create a new board with a name and add it the user.

    public static async Task<IResult> newBoard(int id, BoardsDto boardDto, VtaDevContext db)
    {
    // creates a new board 
    var board = new Board
    {
        UserId = id,
        Name = boardDto.Name
    };

    db.Boards.Add(board);
    await db.SaveChangesAsync();

    return TypedResults.NoContent();

    }
}
