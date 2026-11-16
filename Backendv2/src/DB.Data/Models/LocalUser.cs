using System;
using System.Collections.Generic;

namespace Backendv2.DB.Data;

public partial class LocalUser
{
    public int Id { get; set; }

    public virtual ICollection<Board> Boards { get; set; } = new List<Board>();
}
