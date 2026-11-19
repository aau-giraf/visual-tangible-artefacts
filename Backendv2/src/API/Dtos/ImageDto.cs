using Backendv2.DB.Data.Models.VTAModels;

namespace Backendv2.src.API.DTOs;

public class ImageDto
{
    public int Id {get; set;}

    public ImageDto() { }
    public ImageDto(ImageVta Image) =>
    (Id) = (Image.Id);
}