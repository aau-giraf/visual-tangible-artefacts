//Made by using scaffolding. Started in VTADevContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=VTAConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations;

public class BoardConfiguration : IEntityTypeConfiguration<Board>
{
    public void Configure(EntityTypeBuilder<Board> entity)
    {
        entity.HasKey(e => e.Id).HasName("board_pkey");
        entity.ToTable("board");

        entity.Property(e => e.Id).HasColumnName("id"); // no ValueGeneratedNever
        entity.Property(e => e.Name).HasMaxLength(255).HasColumnName("name");
        entity.Property(e => e.UserId).HasColumnName("userId");

        entity.HasOne(d => d.User).WithMany(p => p.Boards)
            .HasForeignKey(d => d.UserId)
            .HasConstraintName("board_userId_fkey");
    }
}