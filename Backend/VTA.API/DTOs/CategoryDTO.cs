using System;
using System.Collections.Generic;

namespace VTA.API.DTOs;

public partial class CategoryPostDTO
{
    public string CategoryId { get; set; } = null!;

    public byte? CategoryIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? Name { get; set; }
}

public partial class CategoryGetDTO
{
    public string CategoryId { get; set; } = null!;

    public byte? CategoryIndex { get; set; }

    public string? Name { get; set; }

    public virtual ICollection<Models.Artefact> Artefacts { get; set; } = new List<Models.Artefact>();

    public virtual Models.User User { get; set; } = null!;
}
