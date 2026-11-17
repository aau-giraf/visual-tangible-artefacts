namespace Backendv2.DB.Data;
public partial class Organization
{
    public int Id { get; set; }

    public string? Name { get; set; }

    public virtual ICollection<Class> Classes { get; set; } = new List<Class>();

    public virtual ICollection<Image> Images { get; set; } = new List<Image>();

    public virtual ICollection<UserRole> UserRoles { get; set; } = new List<UserRole>();
}
