//Made by using scaffolding 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

namespace Backendv2.DB.Data;

public partial class ArtefactBoard
{
    public int BoardId { get; set; }

    public int ImageId { get; set; }

    public float PosX { get; set; }

    public float PosY { get; set; }

    public int GridX { get; set; }

    public int GridY { get; set; }

    public virtual Board Board { get; set; } = null!;

    public virtual LocalImage Image { get; set; } = null!;
}
