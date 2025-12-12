# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["VTA.API/VTA.API.csproj", "VTA.API/"]
COPY ["VTA.Data/VTA.Data.csproj", "VTA.Data/"]
RUN dotnet restore "VTA.API/VTA.API.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/VTA.API"
RUN dotnet build "VTA.API.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "VTA.API.csproj" -c Release -o /app/publish

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
EXPOSE 8080

# Create Assets directories
RUN mkdir -p /app/Assets/Categories /app/Assets/Artefacts

COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "VTA.API.dll"]
