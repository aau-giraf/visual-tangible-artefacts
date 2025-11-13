using SyncService.Hubs;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", builder =>
    {
        builder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var app = builder.Build();

app.UseRouting();
app.UseCors("AllowFlutter");

app.MapHub<BoardHub>("/boardHub");

app.Run("http://localhost:5002");