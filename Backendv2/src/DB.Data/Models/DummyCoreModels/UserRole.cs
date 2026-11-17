using System;
using System.Collections.Generic;

namespace Backendv2.ModelsDC;

public partial class UserRole
{
    public int NonCitizenId { get; set; }

    public int OrganizationId { get; set; }

    public string Role { get; set; } = null!;

    public virtual NonCitizen NonCitizen { get; set; } = null!;

    public virtual Organization Organization { get; set; } = null!;
}
