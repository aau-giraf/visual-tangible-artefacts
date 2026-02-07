# Class: Program

**Path:** `Backend/SyncService/Program.cs`

## Overview
`Program.cs` is the entry point for the SyncService ASP.NET Core application. Its primary role is to configure and host the SignalR hub (`BoardHub`) for real-time communication and collaboration functionalities. It sets up essential services such as database context, authentication (JWT), authorization, and CORS policies required for a secure and functional real-time service.

## Service Configuration (`builder.Services`)

### Core Services
- **`builder.Services.AddControllers()`**: Registers the services required for MVC controllers. While SyncService is primarily a SignalR host, this might be present for minimal API endpoints or future expansion.
- **`builder.Services.AddSingleton<VTAContext>()`**: Registers `VTAContext` (Entity Framework Core DbContext) as a singleton, ensuring a single instance is used throughout the application.
- **`builder.Services.AddSignalR()`**: Adds the necessary services for SignalR, enabling the creation and management of real-time hubs.
- **`builder.Services.AddResponseCompression(options => { options.EnableForHttps = true; })`**: Adds services for HTTP response compression, optimizing bandwidth usage.

### Authentication & Authorization (JWT)
- **JWT Secret Retrieval**: The application attempts to retrieve the JWT secret from the `JWT_SECRET` environment variable or from `Secret:SecretKey` in `appsettings.json`. If not found, it throws an `ArgumentNullException`.
- **`JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear()`**: Clears default inbound claim type mapping to preserve original JWT claim names.
- **`builder.Services.AddAuthentication(...)`**: Configures the authentication service to use JWT Bearer tokens.
- **`.AddJwtBearer(options => { ... })`**: Configures the JWT Bearer options, including:
  - `MapInboundClaims = false`: Prevents claims transformation.
  - `TokenValidationParameters`: Defines validation rules for incoming JWTs (issuer, audience, lifetime, signing key, role claim type).
- **`builder.Services.AddAuthorization()`**: Adds the authorization service.

### Cross-Origin Resource Sharing (CORS)
- **`builder.Services.AddCors(...)`**: Configures a CORS policy named "AllowAllOrigins" that allows:
  - Any localhost origin (HTTP/HTTPS).
  - Any HTTP method and header.
  - Credentials (e.g., authorization headers).

## Application Configuration (`app.Use...`)

### Middleware Pipeline
- **`app.UseResponseCompression();`**: Adds the response compression middleware to the pipeline.
- **`app.UseCors("AllowAllOrigins");`**: Adds the CORS middleware to apply the defined "AllowAllOrigins" policy.
- **`app.UseAuthentication();`**: Adds the authentication middleware, which authenticates users based on JWT tokens.
- **`app.UseAuthorization();`**: Adds the authorization middleware, which checks user permissions.
- **`app.MapControllers();`**: Maps any defined MVC controller routes.
- **`app.MapHub<BoardHub>("/boardhub");`**: Configures the SignalR endpoint for the `BoardHub` at the path `/boardhub`. This is where clients will connect for real-time communication.
- **`app.Run();`**: Starts the ASP.NET Core web application.

## `public partial class Program { }`
- This empty partial class is provided to ensure that integration tests using `Microsoft.AspNetCore.Mvc.Testing.WebApplicationFactory` can correctly access and configure the `Program` class.

## Internal Imports
- `SyncService.Models` (though not directly used in `Program.cs`, it's part of the `SyncService` project)
- `SyncService.Hubs`

## Notable Packages
- `Microsoft.AspNetCore.Authentication.JwtBearer`
- `Microsoft.AspNetCore.SignalR`
- `Microsoft.IdentityModel.Tokens`
- `System.IdentityModel.Tokens.Jwt`
- `System.Text`
- `Microsoft.EntityFrameworkCore` (implicitly used by `VTAContext`)
- `Microsoft.AspNetCore.Http.Features` (if `FormOptions` were configured)
- `Microsoft.OpenApi.Models` (if Swagger was configured)
- `System.Reflection` (if XML comments for Swagger were configured)
