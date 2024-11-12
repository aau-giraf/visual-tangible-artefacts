using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using VTA.API.DbContexts;
using VTA.API.Utilities;

var builder = WebApplication.CreateBuilder(args);

// test comment test

// Add services to the container.
builder.Services.AddControllers();

builder.WrapDbContext<ArtefactContext>();
builder.WrapDbContext<CategoryContext>();
builder.WrapDbContext<UserContext>();

// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
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

var jwtSecretKey = Environment.GetEnvironmentVariable("JWT_SECRET")
                   ?? config["Secret:SecretKey"];

if (string.IsNullOrEmpty(jwtSecretKey))
{
    throw new ArgumentNullException("JWT_SECRET_KEY environment variable or SecretKey in appsettings.json is required.");
}

var jwtIssuer = "api.vta.com";
var jwtAudience = "user.vta.com";

builder.Services.AddAuthentication(options =>
        {
            options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
        })

    .AddJwtBearer(options =>
            {
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateLifetime = true,
                    ValidateIssuerSigningKey = true,
                    ValidIssuer = jwtIssuer,
                    ValidAudience = jwtAudience,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey)),
                    ClockSkew = TimeSpan.Zero
                };
            });

builder.Services.AddAuthorization();
// Check if Assets directory exists
// Create Assets directory if it does not exist
var assetsDir = Path.Combine(Directory.GetCurrentDirectory(), "Assets");
if (!Directory.Exists(assetsDir))
{
    Directory.CreateDirectory(assetsDir);
}

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Version = "v1",
        Title = "Visual Tangible Artefacts API",
        Description = "An ASP.NET Core API for interfacing with the database",
    });

    options.EnableAnnotations();
    // https://github.com/domaindrivendev/Swashbuckle.AspNetCore/#enrich-operation-metadata
});

var app = builder.Build();

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
app.UseSwagger();
app.UseSwaggerUI();
//}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();

// Don't touch! Integration tests virker ikke hvis Program klassen ikke er erklæret som public, 
// fordi VTA.Tests projektet prøver at bruge Microsoft.AspNetCore.Mvc.Testing.Program istedet for 
// VTA.API Program klassen. 
// https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-8.0#basic-tests-with-the-default-webapplicationfactory 
public partial class Program { }
