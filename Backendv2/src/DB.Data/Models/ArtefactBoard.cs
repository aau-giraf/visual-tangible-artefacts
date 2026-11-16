using System;
using System.Collections.Generic;

namespace Backendv2.DB.Data;

public partial class ArtefactBoard
{
    public int BoardId { get; set; }

    public int ImageId { get; set; }

    public double PosX { get; set; }

    public double PosY { get; set; }

    public int GridX { get; set; }

    public int GridY { get; set; }

    public virtual Board Board { get; set; } = null!;

    public virtual LocalImage Image { get; set; } = null!;
}
