//Made by using scaffolding. Started in VTADevContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class ArtefactBoardConfiguration : IEntityTypeConfiguration<ArtefactBoard>
{
    public void Configure(EntityTypeBuilder<ArtefactBoard> entity)
    {
        entity.HasNoKey().ToTable("artefact-board");

        entity.Property(e => e.BoardId).HasColumnName("boardId");
        entity.Property(e => e.GridX).HasColumnName("gridX");
        entity.Property(e => e.GridY).HasColumnName("gridY");
        entity.Property(e => e.ImageId).HasColumnName("imageId");
        entity.Property(e => e.PosX).HasColumnName("posX");
        entity.Property(e => e.PosY).HasColumnName("posY");

        entity.HasOne(d => d.Board).WithMany()
            .HasForeignKey(d => d.BoardId)
            .HasConstraintName("artefact-board_boardId_fkey");

        entity.HasOne(d => d.Image).WithMany()
            .HasForeignKey(d => d.ImageId)
            .HasConstraintName("artefact-board_imageId_fkey");
    }
}