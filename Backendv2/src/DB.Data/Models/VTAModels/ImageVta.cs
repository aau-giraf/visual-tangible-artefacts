//Made by using scaffolding 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

namespace Backendv2.DB.Data;

public partial class ImageVta
{
    public int Id { get; set; }
}
