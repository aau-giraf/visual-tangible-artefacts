using Xunit;
using Microsoft.EntityFrameworkCore;
using Backendv2.DB.Data;
using Backendv2.src.API.Controllers.boardsController;
using Backendv2.src.API.DTOs.BoardsDto;
using Microsoft.AspNetCore.Http.HttpResults;

//Backendv2/src/Tests/TestProject.csproj
namespace Tests;
public class BoardscontrollerTests
{

    private static VtaDevContext CreateContext(string TestDatabase)
    {
        var options = new DbContextOptionsBuilder<VtaDevContext>()
           .UseInMemoryDatabase(TestDatabase)
           .Options;

        return new VtaDevContext(options);
    }

[Fact]
// Tests if a board exist and belongs to a selected user, if that true then return ok.
public async Task getBoard_returnABoard()

{    
    using var db = CreateContext("TestDatabase0");
    db.Boards.Add(new Board
    {
        Id = 1,
        UserId = 10,
        Name = "my board"
    });
    
    await db.SaveChangesAsync();

    var result = await boardsController.getBoard(10, 1, db);
    var board = Assert.IsType<Ok<BoardsDto>>(result);
    Assert.Equal("my board", board.Value!.Name);

    }

 [Fact]
//Test if a board does not exist the return Not Found.
public async Task getBoard_returnNotFound()
    {
           using var db = CreateContext("TestDatabase1");
           var result = await boardsController.getBoard(10,1,db );
           Assert.IsType<NotFound>(result);
    
    }

[Fact]
//Tests if a board exist, but belongs to a different user then it returns Not Found.
public async Task getBoard_BelongsToAnotherUser_returnNotfound()

    {
             using var db = CreateContext("TestDatabase2");
             db.Boards.Add(new Board
            {
                Id=1,
                UserId =12,
                Name = " køkkenet "

            });
            
            await db.SaveChangesAsync();
            var result = await boardsController.getBoard(10,1,db);
            Assert.IsType<NotFound>(result);
    }

[Fact]
//Tests if it gets all boards belonging to a selected user.
public async Task getAllboards_returnOk()

    {
           using var db =  CreateContext("TestDatabase3");
               db.Boards.AddRange(

                new Board {Id = 1, UserId=12, Name="board1"},

                new Board {Id= 2, UserId= 12, Name= "board2"},

                new Board {Id = 3,UserId= 16, Name="board3" }

               );

          await db.SaveChangesAsync();
          var results = await boardsController.getAllBoards(12,db);
          var boards = Assert.IsType<Ok<List<BoardsDto>>>(results);
          Assert.Equal(2, boards.Value!.Count);
              
    }

[Fact]
//Tests if a selected user does not have any boards, and then returns empty list.
public async Task getAllBoards_returnemptylist()
    {
        using var db = CreateContext("TestDatabase4");
        var results =  await boardsController.getAllBoards(12,db);
        var boards = Assert.IsType<Ok<List<BoardsDto>>>(results);
        Assert.Empty(boards.Value!);

    }

[Fact]
// Tests if the board is created and saved in the DB. 
public async Task newBoard_returnNoContet()

    {
           using var db =  CreateContext("TestDatabase5");
           var boardDto = new BoardsDto
           {
               Name = "my new board"
           };

           var result = await boardsController.newBoard(12,boardDto, db);
           Assert.IsType<NoContent>(result);

           var board = await db.Boards.FirstOrDefaultAsync(board => board.UserId == 12);

           Assert.NotNull(board);
           Assert.Equal("my new board", board.Name);  

    }

}