using System;
using System.Collections.Generic;

namespace VTA.API.DTOs;

public partial class UserPostDTO
{
    public required string? Name { get; set; }

    public required string Password { get; set; }

    public string GuardianKey { get; set; } = null!;

    public string Username { get; set; } = null!;
}

public partial class UserGetDTO
{
    public string Id { get; set; } = null!;

    public string? Name { get; set; }

    public string Password { get; set; } = null!;

    public string GuardianKey { get; set; } = null!;

    public string Username { get; set; } = null!;

    public virtual ICollection<Models.Artefact> Artefacts { get; set; } = new List<Models.Artefact>();

    public virtual ICollection<Models.Category> Categories { get; set; } = new List<Models.Category>();
}