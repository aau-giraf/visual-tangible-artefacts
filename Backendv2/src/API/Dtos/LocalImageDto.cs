using Backendv2.DB.Data.Models.VTAModels;

namespace Backendv2.src.API.Routes.DTOs.LocalImageDto;

public class LocalImageDto
{
    public int Id {get; set;}

    public LocalImageDto() { }
    public LocalImageDto(LocalImage LocalImage) =>
    (Id) = (LocalImage.Id);
}