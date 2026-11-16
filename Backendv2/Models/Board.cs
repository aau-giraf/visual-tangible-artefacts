using System;
using System.Collections.Generic;

namespace Backendv2.Models;

public partial class Board
{
    public int Id { get; set; }

    public int Userid { get; set; }

    public string Name { get; set; } = null!;
}
