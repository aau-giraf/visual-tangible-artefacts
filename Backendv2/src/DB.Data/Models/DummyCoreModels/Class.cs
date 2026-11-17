using System;
using System.Collections.Generic;

namespace Backendv2.ModelsDC;

public partial class Class
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public int OrganizationId { get; set; }

    public virtual ICollection<Citizen> Citizens { get; set; } = new List<Citizen>();

    public virtual Organization Organization { get; set; } = null!;
}
