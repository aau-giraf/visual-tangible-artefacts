using VTA.API.Models.Categories;

namespace VTA.API.Models.Artefacts;

public class DefaultArtefact : Artefact
{
    public virtual DefaultCategory? Category { get; set; }
}