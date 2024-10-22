using Microsoft.EntityFrameworkCore;
using VTA.API.DbContexts;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();

builder.WrapDbContext<ArtefactContext>();
builder.WrapDbContext<CategoryContext>();
builder.WrapDbContext<UserContext>();


// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
app.UseSwagger();
app.UseSwaggerUI();
//}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();

app.Run();

// Don't touch! Integration tests virker ikke hvis Program klassen ikke er deklareret som partial, 
// fordi VTA.Tests projektet prøver at bruge Microsoft.AspNetCore.Mvc.Testing.Program istedet for 
// VTA.API Program klassen.  
public partial class Program { }
