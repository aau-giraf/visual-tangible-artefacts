# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy csproj files and restore dependencies
COPY ["SyncService/SyncService.csproj", "SyncService/"]
COPY ["VTA.API/VTA.API.csproj", "VTA.API/"]
RUN dotnet restore "SyncService/SyncService.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/SyncService"
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