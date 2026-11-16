using System;
using System.Collections.Generic;

namespace Backendv2.Models;

public partial class ArtefactBoard
{
    public int Boardid { get; set; }

    public int Imageid { get; set; }

    public double PosX { get; set; }

    public double PosY { get; set; }

    public int GridX { get; set; }

    public int GridY { get; set; }

    public virtual Board Board { get; set; } = null!;
}
