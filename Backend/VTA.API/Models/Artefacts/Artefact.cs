namespace VTA.API.Models.Artefacts;

public abstract class Artefact
{
    public required Guid Id { get; set; }

    public required ushort ArtefactIndex { get; set; }

    public Guid? CategoryId { get; set; }

    public string? ImagePath { get; set; } = null!;
    public string? SoundPath { get; set; } = null!;
    public DateTime? ModifiedDate { get; set; }
    public string? Name { get; set; }
    
    public bool? NameShown { get; set; }
}
