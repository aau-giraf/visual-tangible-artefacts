# Class: Program

**Path:** `Backend/VTA.API/Program.cs`

## Overview
`Program.cs` is the entry point for the Visual Tangible Artefacts (VTA) ASP.NET Core Web API. It is responsible for configuring the application's services (Dependency Injection container) and defining the HTTP request processing pipeline (middleware). This file sets up database access, authentication (JWT), authorization, CORS policies, Swagger/OpenAPI documentation, file serving, and other foundational aspects of the API.

## Service Configuration (`builder.Services`)

### Core Services
- **`builder.Services.AddControllers()`**: Registers the services required for MVC controllers, enabling the API to handle HTTP requests.
- **`builder.Services.AddResponseCompression(options => { options.EnableForHttps = true; })`**: Adds services for HTTP response compression, improving bandwidth usage by compressing responses, particularly for HTTPS traffic.
- **`builder.Services.AddHttpClient()`**: Registers `HttpClient` and `IHttpClientFactory` services, allowing for making outgoing HTTP requests (e.g., to the ElevenLabs API).
- **`builder.Services.AddVTAContext(builder.Configuration)`**: A custom extension method (`VTA.Data.Extensions.VTAContextExtensions`) that configures and registers the `VTAContext` (Entity Framework Core DbContext) with the dependency injection container, typically including database connection string setup.

### API Documentation (Swagger/OpenAPI)
- **`builder.Services.AddEndpointsApiExplorer()`**: Adds services to discover API endpoints, used by Swagger.
- **`builder.Services.AddSwaggerGen(...)`**: Configures Swagger/OpenAPI generation:
  - Defines API metadata (`OpenApiInfo`).
  - Includes XML comments from the executing assembly for richer documentation.
  - Adds JWT Bearer authentication support to the Swagger UI, allowing users to provide a token for testing protected endpoints.

### Secret Management
- **`builder.Services.AddSingleton(provider => { ...SecretsProvider.Instance... })`**: Registers `SecretsProvider` as a singleton. It retrieves the "SecretKey" from configuration (or environment variable) and adds it to the `SecretsProvider.Instance`.

### Authentication & Authorization (JWT)
- **JWT Secret Retrieval**: The application attempts to retrieve the JWT secret from the `JWT_SECRET` environment variable (for production/CI) or from `Secret:SecretKey` in `appsettings.json` (for development). If neither is found, it throws an `ArgumentNullException`.
- **`JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear()`**: Prevents JWT claims from being mapped to Microsoft-specific claim types, ensuring that claims like "role" are used as-is.
- **`builder.Services.AddAuthentication(...)`**: Configures the authentication service to use JWT Bearer tokens as the default scheme.
- **`.AddJwtBearer(options => { ... })`**: Configures the JWT Bearer options:
  - `MapInboundClaims = false`: Prevents claims transformation.
  - `TokenValidationParameters`: Defines parameters for validating incoming JWTs, including `ValidateIssuer`, `ValidateAudience`, `ValidateLifetime`, `ValidateIssuerSigningKey`, `ValidIssuer`, `ValidAudience`, `IssuerSigningKey` (derived from `jwtSecretKey`), `ClockSkew` (set to `TimeSpan.Zero`), and `RoleClaimType` (set to "role").
- **`builder.Services.AddAuthorization()`**: Adds the authorization service, enabling role-based and policy-based authorization.

### Cross-Origin Resource Sharing (CORS)
- **`builder.Services.AddCors(...)`**: Configures a CORS policy named "AllowAllOrigins" that:
  - Allows `http://localhost:*` and `https://localhost:*` origins (and `127.0.0.1`).
  - Allows any HTTP method and header.
  - Allows sending credentials (e.g., cookies, authorization headers).

### Request Size Limits
- **`builder.WebHost.ConfigureKestrel(...)`**: Configures the Kestrel web server to set a maximum request body size (e.g., 150 MB), primarily for file uploads.
- **`builder.Services.Configure<FormOptions>(...)`**: Configures form options, specifically setting `MultipartBodyLengthLimit` for multipart form data (also 150 MB).

## Application Configuration (`app.Use...`)

### Assets Directory Setup
- Checks if `Assets`, `Assets/Categories`, `Assets/Artefacts`, and `Assets/Sounds` directories exist under the current working directory. If not, it creates them. These directories are used for storing uploaded media files.

### Database Migration
- **`if (app.Environment.IsDevelopment()) { await app.MigrateVTAContext(); }`**: In the development environment, calls a custom extension method (`VTA.API.Extensions.WebApplicationExtensions.MigrateVTAContext`) to automatically create or migrate the database schema and seed initial test data.

### Middleware Pipeline
- **`app.UseSwagger(); app.UseSwaggerUI();`**: Enables the Swagger JSON endpoint and the interactive Swagger UI for API documentation and testing.
- **`app.UseResponseCompression();`**: Adds the response compression middleware to the pipeline.
- **`app.UseCors("AllowAllOrigins");`**: Adds the CORS middleware to apply the defined "AllowAllOrigins" policy.
- **`app.UseAuthentication();`**: Adds the authentication middleware, which attempts to authenticate the user based on incoming requests (e.g., by validating JWT tokens).
- **`app.UseAuthorization();`**: Adds the authorization middleware, which checks if the authenticated user has permission to access specific resources or endpoints.
- **`app.MapControllers();`**: Maps incoming requests to controller actions.
- **`app.Run();`**: Starts the ASP.NET Core web application.

## `public partial class Program { }`
- This empty partial class is crucial for enabling integration tests using `Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactory`. It makes the `Program` class accessible to the test project, preventing issues where the test runner might otherwise try to use a different `Program` class.

## Internal Imports
- `VTA.API.Extensions`
- `VTA.API.Utilities`
- `VTA.Data.Extensions`

## Notable Packages
- `Microsoft.AspNetCore.Authentication.JwtBearer`
- `Microsoft.AspNetCore.Http.Features`
- `Microsoft.IdentityModel.Tokens`
- `Microsoft.OpenApi.Models`
- `System.IdentityModel.Tokens.Jwt`
- `System.Reflection`
- `System.Text`
- `Microsoft.AspNetCore.Builder`
- `Microsoft.Extensions.Configuration`
- `Microsoft.Extensions.DependencyInjection`
- `Microsoft.AspNetCore.Hosting`
