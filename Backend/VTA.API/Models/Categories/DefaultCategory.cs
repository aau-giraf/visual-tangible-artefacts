using VTA.API.Models.Artefacts;

namespace VTA.API.Models.Categories;

public class DefaultCategory : Category
{
    public virtual ICollection<DefaultArtefact> Artefacts { get; set; } = new List<DefaultArtefact>();
}