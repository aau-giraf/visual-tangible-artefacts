using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.IdentityModel.Tokens.Jwt;
using System.Reflection;
using System.Text;
using VTA.API.DbContexts;
using VTA.API.Extensions;
using VTA.API.Utilities;

var builder = WebApplication.CreateBuilder(args);

JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear();

// test comment test, test push, test

// Add services to the container.
builder.Services.AddControllers();

// Add response compression for better bandwidth usage
builder.Services.AddResponseCompression(options =>
{
    options.EnableForHttps = true;
});

// Add HttpClient services for ElevenLabs API integration
builder.Services.AddHttpClient();

// Register our DB context
builder.AddVTAContext();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
//register our singleton
builder.Services.AddSingleton(provider =>
    {
        var secretsSingleton = SecretsProvider.Instance;
        secretsSingleton.AddSecret("SecretKey", builder.Configuration.GetSection("Secret")["SecretKey"]);
        return secretsSingleton;
    }
);

var config = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables()
    .Build();

var jwtSecretKey = Environment.GetEnvironmentVariable("JWT_SECRET") //I still do not know why this was added, we are reading the Secretkey from appsettings, not the OS env variables
                   ?? config["Secret:SecretKey"];//load our secret

if (string.IsNullOrEmpty(jwtSecretKey))
{
    throw new ArgumentNullException("JWT_SECRET_KEY environment variable or SecretKey in appsettings.json is required.");
}
/*Configure Json Web Tokens*/
var jwtIssuer = "api.vta.com";
var jwtAudience = "user.vta.com";

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
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtIssuer,
                    ValidAudience = jwtAudience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
                    ClockSkew = TimeSpan.Zero,
                    RoleClaimType = "role"
                };
            });

builder.Services.AddAuthorization();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAllOrigins", policy =>
    {
        // Allow any localhost origin for development (required when using AllowCredentials)
        policy.SetIsOriginAllowed(origin => 
                origin.StartsWith("http://localhost:", StringComparison.OrdinalIgnoreCase) ||
                origin.StartsWith("https://localhost:", StringComparison.OrdinalIgnoreCase) ||
                origin.StartsWith("http://127.0.0.1:", StringComparison.OrdinalIgnoreCase) ||
                origin.StartsWith("https://127.0.0.1:", StringComparison.OrdinalIgnoreCase))
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Check if Assets directories exists and create them if not
var assetsDirs = Path.Combine(Directory.GetCurrentDirectory(), "Assets");
if (!Directory.Exists(assetsDirs))
{
    Directory.CreateDirectory(assetsDirs);
}
assetsDirs = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Categories");
if (!Directory.Exists(assetsDirs))
{
    Directory.CreateDirectory(assetsDirs);
}
assetsDirs = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Artefacts");
if (!Directory.Exists(assetsDirs))
{
    Directory.CreateDirectory(assetsDirs);
}
assetsDirs = Path.Combine(Directory.GetCurrentDirectory(), "Assets", "Sounds");
if (!Directory.Exists(assetsDirs))
{
    Directory.CreateDirectory(assetsDirs);
}

builder.Services.AddEndpointsApiExplorer();
//Swagger ui stuff
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "Visual Tangible Artefacts API",
        Description = "An ASP.NET Core API for interfacing with the database",
    });
    options.IncludeXmlComments(Assembly.GetExecutingAssembly());//For XML comments to be included in the swagger UI https://github.com/domaindrivendev/Swashbuckle.AspNetCore/?tab=readme-ov-file#include-descriptions-from-xml-comments
    //options.EnableAnnotations();// For using Attributes to document the swagger UI https://github.com/domaindrivendev/Swashbuckle.AspNetCore/#enrich-operation-metadata

        // Add JWT Authentication to Swagger
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "JWT Authorization header using the Bearer scheme. Enter your token in the text input below.\r\n\r\nExample: \"abc123token\""
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 150 * 1024 * 1024; // 150 MB
});

builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 150 * 1024 * 1024; // 150 MB
});

var app = builder.Build();

// Auto-create database if environment variable is set for docker compose
if (app.Environment.IsDevelopment())
{
    await app.MigrateVTAContext();
}

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
app.UseSwagger();
app.UseSwaggerUI();
//}

//app.UseHttpsRedirection();

app.UseResponseCompression();
app.UseCors("AllowAllOrigins");
app.UseAuthentication();
app.UseAuthorization();


app.MapControllers();

app.Run();

// Don't touch! Integration tests virker ikke hvis Program klassen ikke er erklæret som public, 
// fordi VTA.Tests projektet prøver at bruge Microsoft.AspNetCore.Mvc.Testing.Program istedet for 
// VTA.API Program klassen. 
// https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-8.0#basic-tests-with-the-default-webapplicationfactory 
public partial class Program { }