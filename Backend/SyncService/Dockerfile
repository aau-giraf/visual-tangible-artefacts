# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["SyncService.csproj", "./"]
RUN dotnet restore "SyncService.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "SyncService.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "SyncService.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app
EXPOSE 8080

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "SyncService.dll"]