using System;
using System.Collections.Generic;

namespace Backendv2.ModelsDC;

public partial class NonCitizen
{
    public int Id { get; set; }

    public string? Email { get; set; }

    public virtual User IdNavigation { get; set; } = null!;

    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();

    public virtual ICollection<Citizen> Citizens { get; set; } = new List<Citizen>();
}
