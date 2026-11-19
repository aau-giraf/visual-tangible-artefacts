using Microsoft.AspNetCore.Http.HttpResults;
using Backendv2.src.API.Routes;
using Backendv2.src.API.DTOs;
using Microsoft.VisualBasic;

namespace Backendv2.src.API.Controllers;

public class ArtefactBoardHandler(int boardId, int imageId, double posX, double posY, int gridX, int gridY)
{
    public ArtefactBoardDto AB = new ArtefactBoardDto
    {
        BoardId = boardId,
        ImageId = imageId,
        PosX = posX,
        PosY = posY,
        GridX = gridX,
        GridY = gridY
    };
}