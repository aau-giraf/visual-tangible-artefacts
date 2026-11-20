namespace Backendv2.DB.Data.Models.DummyCoreModels;

public partial class Guardianship
{
    public int CitizenId { get; set; }
    public int GuardianId { get; set; }

    public virtual Citizen Citizen { get; set; } = null!;
    public virtual NonCitizen Guardian { get; set; } = null!;
}

public partial class Citizen
{
    public virtual ICollection<Guardianship> Guardianships { get; set; } = new List<Guardianship>();
}

public partial class NonCitizen
{
    public virtual ICollection<Guardianship> Guardianships { get; set; } = new List<Guardianship>();
}