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

[Fact]

public async Task getBoard_returnABoard()

{    

var options = new DbContextOptionsBuilder<VtaDevContext>()
    .UseInMemoryDatabase("TestDatabase0")
    .Options;


    using var db = new VtaDevContext(options);

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

public async Task getBoard_returnNotFound()
    {
        var options = new DbContextOptionsBuilder<VtaDevContext>()
          .UseInMemoryDatabase("testdatabase1")
          .Options;


           using var db = new VtaDevContext(options);

           var result = await boardsController.getBoard(10,1,db );

           Assert.IsType<NotFound>(result);

    
    }





[Fact]
public async Task getBoard_BelongsToAnotherUser_returnNotfound()

    {
        var options = new DbContextOptionsBuilder<VtaDevContext>()
             .UseInMemoryDatabase("testdatabase2")
             .Options;


             using var db = new VtaDevContext(options);
        
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

public async Task getAllboards_returnOk()

    {
        var options = new DbContextOptionsBuilder<VtaDevContext>()
           .UseInMemoryDatabase("testdatabase3")
           .Options;

           using var db = new VtaDevContext(options);

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


public async Task getAllBoards_returnemptylist()
    {

        var options = new DbContextOptionsBuilder<VtaDevContext>()
            .UseInMemoryDatabase("testdatabase4")
            .Options;


        using var db = new VtaDevContext(options);

        var results =  await boardsController.getAllBoards(12,db);

        var boards = Assert.IsType<Ok<List<BoardsDto>>>(results);

        Assert.Empty(boards.Value!);


    }

[Fact]
// this test if the board is created and saved in the DB. 
public async Task newBoard_returnNoContet()

    {

        var options = new DbContextOptionsBuilder<VtaDevContext>()
           .UseInMemoryDatabase("testdatabase5")
           .Options;


           using var db = new VtaDevContext(options);
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


