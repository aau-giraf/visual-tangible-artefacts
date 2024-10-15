﻿using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Pomelo.EntityFrameworkCore.MySql.Scaffolding.Internal;
using VTA.API.Models;

namespace VTA.API.DbContexts;

public partial class CategoryContext : DbContext
{
    public CategoryContext()
    {
    }

    public CategoryContext(DbContextOptions<CategoryContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Artefact> Artefacts { get; set; }

    public virtual DbSet<Category> Categories { get; set; }

    public virtual DbSet<User> Users { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
#warning To protect potentially sensitive information in your connection string, you should move it out of source code. You can avoid scaffolding the connection string by using the Name= syntax to read it from configuration - see https://go.microsoft.com/fwlink/?linkid=2131148. For more guidance on storing connection strings, see https://go.microsoft.com/fwlink/?LinkId=723263.
        => optionsBuilder.UseMySql("server=giraf-vta01.srv.aau.dk;port=3306;user=dotnet;password=DotnetAPI12345;database=VTA", Microsoft.EntityFrameworkCore.ServerVersion.Parse("8.0.39-mysql"));

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .UseCollation("utf8mb4_0900_ai_ci")
            .HasCharSet("utf8mb4");

        modelBuilder.Entity<Artefact>(entity =>
        {
            entity.HasKey(e => e.ArtefactId).HasName("PRIMARY");

            entity.ToTable("artefact");

            entity.HasIndex(e => e.CategoryId, "categoryId");

            entity.HasIndex(e => e.UserId, "userId");

            entity.Property(e => e.ArtefactId)
                .HasMaxLength(36)
                .HasColumnName("artefactId");
            entity.Property(e => e.ArtefactIndex).HasColumnName("artefactIndex");
            entity.Property(e => e.CategoryId)
                .HasMaxLength(36)
                .HasColumnName("categoryId");
            entity.Property(e => e.ImagePath)
                .HasMaxLength(255)
                .HasColumnName("imagePath");
            entity.Property(e => e.UserId)
                .HasMaxLength(36)
                .HasColumnName("userID");

            entity.HasOne(d => d.Category).WithMany(p => p.Artefacts)
                .HasForeignKey(d => d.CategoryId)
                .HasConstraintName("artefact_ibfk_2");

            entity.HasOne(d => d.User).WithMany(p => p.Artefacts)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("artefact_ibfk_1");
        });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.HasKey(e => e.CategoryId).HasName("PRIMARY");

            entity.ToTable("category");

            entity.HasIndex(e => e.UserId, "userId");

            entity.Property(e => e.CategoryId)
                .HasMaxLength(36)
                .HasColumnName("categoryId");
            entity.Property(e => e.CategoryIndex).HasColumnName("categoryIndex");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.UserId)
                .HasMaxLength(36)
                .HasColumnName("userId");

            entity.HasOne(d => d.User).WithMany(p => p.Categories)
                .HasForeignKey(d => d.UserId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("category_ibfk_1");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PRIMARY");

            entity.ToTable("user");

            entity.Property(e => e.Id)
                .HasMaxLength(36)
                .HasColumnName("id");
            entity.Property(e => e.GuardianKey)
                .HasMaxLength(255)
                .HasColumnName("guardianKey");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.Password)
                .HasMaxLength(255)
                .HasColumnName("password");
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .HasColumnName("username");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
