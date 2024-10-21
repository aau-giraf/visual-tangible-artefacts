using System;
using System.Collections.Generic;

namespace VTA.API.Models;

public partial class Artefact
{
    public string ArtefactId { get; set; } = null!;

    public ushort ArtefactIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? CategoryId { get; set; }

    public string? ImagePath { get; set; }

    public virtual Category? Category { get; set; }

    public virtual User User { get; set; } = null!;
}
