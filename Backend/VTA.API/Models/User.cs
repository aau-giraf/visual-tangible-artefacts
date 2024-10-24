using System;
using System.Collections.Generic;

namespace VTA.API.Models;

public partial class User
{
    public required string Id { get; set; }

    public string? Name { get; set; }

    public required string Password { get; set; }

    public string GuardianKey { get; set; } = null!;

    public string Username { get; set; } = null!;

    public virtual ICollection<Artefact> Artefacts { get; set; } = new List<Artefact>();

    public virtual ICollection<Category> Categories { get; set; } = new List<Category>();
}
