using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SyncService.Hubs;
using SyncService.Services;
using VTA.Data.Extensions;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddVTAContext(builder.Configuration);

// BoardHub services (singletons — they own shared in-memory state)
builder.Services.AddSingleton<IPresenceService, PresenceService>();
builder.Services.AddSingleton<ISessionService, SessionService>();
builder.Services.AddSingleton<IBoardSyncRelay, BoardSyncRelay>();

builder.Services.AddSignalR();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutter", policyBuilder =>
    {
        policyBuilder.AllowAnyOrigin()
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var config = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables()
    .Build();

var jwtSecretKey = Environment.GetEnvironmentVariable("JWT_SECRET")
                   ?? config["Secret:SecretKey"];

if (string.IsNullOrEmpty(jwtSecretKey))
{
    throw new ArgumentNullException("JWT_SECRET environment variable or Secret:SecretKey in appsettings.json is required.");
}

// Configure JWT validation for Core-issued tokens
builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })
    .AddJwtBearer(options =>
            {
                options.MapInboundClaims = false;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = false,
                    ValidateAudience = false,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
                };
                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        var accessToken = context.Request.Query["access_token"];
                        var path = context.HttpContext.Request.Path;
                        if (!string.IsNullOrEmpty(accessToken) &&
                            path.StartsWithSegments("/boardHub"))
                        {
                            context.Token = accessToken;
                        }
                        return Task.CompletedTask;
                    }
                };
            });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseRouting();
app.UseCors("AllowFlutter");
app.UseAuthentication();
app.UseAuthorization();
app.MapHub<BoardHub>("/boardHub");

await app.RunAsync();