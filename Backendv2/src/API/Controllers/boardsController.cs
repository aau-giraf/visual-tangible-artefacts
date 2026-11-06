
namespace  Backendv2.src.API.Controllers.boardsController;

public class Board (int id, float posX, float posy, int gridX, int gridY)
{
    public int id { get; set; } = id;
    public float posX { get; set; } = posX;
    public float posy { get; set; } = posy;
    public int gridX { get; set; } = gridX;
    public int gridY { get; set; } = gridY;
    
}


public class boardsController
{
    Board board1 = new Board(1, 3.2f, 6.4f, 5, 5);
    
    public static Board getboard(Board board1)
    {
        // Find the user with the board

        // If the user is found, return the board
        return board1;
    }

    public static string getAllBoards()
    {
        // Find the user then return all the boards that the user has


        return "placeholder";
    }

    public static string newBoard()
    {
        // Create a new board with a name and add it the user


        return "204 No Content";
    }
}
