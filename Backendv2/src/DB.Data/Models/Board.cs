using System;
using System.Collections.Generic;

namespace Backendv2.DB.Data;

public partial class Board
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string Name { get; set; } = null!;

    public virtual LocalUser User { get; set; } = null!;
}
