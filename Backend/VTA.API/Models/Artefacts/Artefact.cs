namespace VTA.API.Models.Artefacts;

public abstract class Artefact
{
    public required string ArtefactId { get; set; }

    public required ushort ArtefactIndex { get; set; }

    public string? CategoryId { get; set; }

    public string? ImagePath { get; set; } = null!;
    public string? SoundPath { get; set; } = null!;
    public DateTime? ModifiedDate { get; set; }
    public string? Name { get; set; }
    
    //public bool? NameShown { get; set; }
}
