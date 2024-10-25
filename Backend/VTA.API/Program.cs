using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.Identity.Client;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using VTA.API.DbContexts;
using VTA.API.Utilities;

var builder = WebApplication.CreateBuilder(args);

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

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
}

    ).AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters()
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration.GetSection("Secret")["ValidIssuer"],
            ValidAudience = builder.Configuration.GetSection("Secret")["ValidAudience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration.GetSection("Secret")["SecretKey"])),
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

// Don't touch! Integration tests virker ikke hvis Program klassen ikke er deklareret som partial, 
// fordi VTA.Tests projektet prøver at bruge Microsoft.AspNetCore.Mvc.Testing.Program istedet for 
// VTA.API Program klassen. 
// https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-8.0#basic-tests-with-the-default-webapplicationfactory 
public partial class Program { }
