using Backendv2.DB.Data;

namespace Backendv2.src.API.Routes.DTOs.BoardsDto;

public class BoardsDto()
{
    public string Name {get; set;}

    public BoardsDto() { }
    public BoardsDto(Board Board) =>
    (Name) = (Board.Name);
}