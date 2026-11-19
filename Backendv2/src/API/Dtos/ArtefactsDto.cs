using Backendv2.DB.Data;

namespace Backendv2.src.API.DTOs;

public class ArtefactsDto
{
    public int ImageId {get; set;}
    public int UseCount {get; set;}

    public ArtefactsDto() { }
    public ArtefactsDto(Artefact Artefact) => 
    (ImageId, UseCount) = (Artefact.ImageId, Artefact.UseCount);
}