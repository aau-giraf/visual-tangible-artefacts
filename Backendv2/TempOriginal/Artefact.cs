using System;
using System.Collections.Generic;

namespace Backendv2.TempOriginal;

public partial class Artefact
{
    public int ImageId { get; set; }

    public int UseCount { get; set; }

    public virtual LocalImage Image { get; set; } = null!;
}
