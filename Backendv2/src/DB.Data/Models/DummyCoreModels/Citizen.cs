namespace Backendv2.DB.Data.Models.DummyCoreModels;

public partial class Citizen
{
    public int Id { get; set; }

    public int ClassId { get; set; }

    public virtual Class Class { get; set; } = null!;

    public virtual User IdNavigation { get; set; } = null!;

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();
}
