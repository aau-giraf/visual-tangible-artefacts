using System;
using System.Collections.Generic;

namespace Backendv2.DB.Data;

public partial class Artefact
{
    public int ImageId { get; set; }

    public int UseCount { get; set; }

    public virtual LocalImage Image { get; set; } = null!;
}
