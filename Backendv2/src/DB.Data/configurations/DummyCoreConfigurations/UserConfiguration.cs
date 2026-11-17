//Made by using scaffolding. Started in DummyCoreContext. Have been mordified so it can be in separate files 
//Command: dotnet ef dbcontext scaffold "Name=DummyCoreConnectionString” Npgsql.EntityFrameworkCore.PostgreSQL -o Models -f
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Backendv2.DB.Data.Configurations.DummyCoreConfigurations;

    public class UserConfiguration : IEntityTypeConfiguration<User>
{
        public void Configure(EntityTypeBuilder<User> entity)
        {
            entity.HasKey(e => e.Id).HasName("user_pkey");

            entity.ToTable("user");

            entity.HasIndex(e => e.UserName, "user_userName_key").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.FirstName).HasMaxLength(65).HasColumnName("firstName");
            entity.Property(e => e.LastName).HasMaxLength(65).HasColumnName("lastName");
            entity.Property(e => e.Password).HasMaxLength(65).HasColumnName("password");
            entity.Property(e => e.UserName).HasMaxLength(65).HasColumnName("userName");
}}