using System;
using System.Collections.Generic;

namespace VTA.API.Models;

public partial class Category
{
    public string CategoryId { get; set; } = null!;

    public byte? CategoryIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? Name { get; set; }

    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();

    public virtual User User { get; set; } = null!;
}
