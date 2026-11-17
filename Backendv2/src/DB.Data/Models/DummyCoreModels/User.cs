using System;
using System.Collections.Generic;
using Backendv2.ModelsDC;

namespace Backendv2.DB.Data;

public partial class User
{
    public int Id { get; set; }

    public string? FirstName { get; set; }

    public string? LastName { get; set; }

    public string UserName { get; set; } = null!;

    public string Password { get; set; } = null!;

    public virtual Citizen? Citizen { get; set; }

    public virtual NonCitizen? NonCitizen { get; set; }
}
