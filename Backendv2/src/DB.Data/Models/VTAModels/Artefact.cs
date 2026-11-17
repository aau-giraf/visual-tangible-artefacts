//Made by using scaffolding 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

namespace Backendv2.DB.Data;

public partial class Artefact
{
    public int ImageId { get; set; }

    public int UseCount { get; set; }

    public virtual LocalImage Image { get; set; } = null!;
}
