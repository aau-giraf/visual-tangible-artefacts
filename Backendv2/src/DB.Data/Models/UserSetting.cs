using System;
using System.Collections.Generic;

namespace Backendv2.DB.Data;

public partial class UserSetting
{
    public int UserId { get; set; }

    public bool Contrast { get; set; }

    public bool Lightmode { get; set; }

    public bool Darkmode { get; set; }

    public string Language { get; set; } = null!;

    public bool SentenceBar { get; set; }

    public virtual LocalUser User { get; set; } = null!;
}
