//Made by using scaffolding 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

namespace Backendv2.DB.Data;

public partial class User
{
    public int Id { get; set; }
}
