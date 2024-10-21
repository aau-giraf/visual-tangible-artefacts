﻿using System;
using System.Collections.Generic;

namespace VTA.API.DTOs;

public partial class ArtefactPostDTO
{
    public string ArtefactId { get; set; } = null!;

    public ushort ArtefactIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? CategoryId { get; set; }

    public IFormFile? Image { get; set; }
}

public partial class ArtefactGetDTO
{
    public string ArtefactId { get; set; } = null!;

    public ushort ArtefactIndex { get; set; }

    public string UserId { get; set; } = null!;

    public string? CategoryId { get; set; }

    public string? ImageUrl { get; set; }
}