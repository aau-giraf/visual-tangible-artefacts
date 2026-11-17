using Backendv2.DB.Data;

namespace Backendv2.src.API.Routes.DTOs.ArtefactBoardDto;

public class ArtefactBoardDto()
{
    public int BoardId {get; set;}
    public int ImageId {get; set;}
    public double PosX {get; set;}
    public double PosY {get; set;}
    public int GridX {get; set;}
    public int GridY {get; set;}

    public ArtefactBoardDto() { }
    public ArtefactBoardDto(ArtefactBoard ArtefactBoard) => 
    (BoardId, ImageId, PosX, PosY, GridX, GridY) = (ArtefactBoard.BoardId, ArtefactBoard.ImageId, ArtefactBoard.PosX, ArtefactBoard.PosY, ArtefactBoard.GridX, ArtefactBoard.GridY);
}