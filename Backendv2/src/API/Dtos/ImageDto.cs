using Backendv2.DB.Data;

namespace Backendv2.src.API.Routes.DTOs.ImageDto;

public class ImageDto
{
    public int Id {get; set;}

    public ImageDto() { }
    public ImageDto(Image Image) =>
    (Id) = (Image.Id);
}
