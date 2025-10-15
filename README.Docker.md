# Docker Setup for VTA

This guide explains how to run the Visual Tangible Artefacts application using Docker.

## Prerequisites

- Docker (version 20.10 or later)
- Docker Compose (version 2.0 or later)

## Quick Start

1. **Start all services:**
   ```bash
   docker-compose up -d
   ```

2. **Access the services:**
   - Frontend: http://localhost:8080
   - Backend API: http://localhost:5192
   - Backend Swagger: http://localhost:5192/swagger
   - MySQL: localhost:3306

3. **Stop all services:**
   ```bash
   docker-compose down
   ```

4. **Stop and remove volumes (clean database):**
   ```bash
   docker-compose down -v
   ```

## Services

### MySQL Database
- **Container:** `vta-mysql`
- **Port:** 3306
- **Database:** `vta_dev`
- **User:** `vta_user`
- **Password:** `vta_password`
- **Root Password:** `root_password`

### Backend API
- **Container:** `vta-backend`
- **Port:** 5192 (maps to container port 8080)
- **Environment:** Development
- **Connection String:** Configured automatically to connect to MySQL

### Frontend
- **Container:** `vta-frontend`
- **Port:** 8080 (maps to container port 80)
- **Technology:** Flutter Web served by nginx

## Environment Variables

You can customize the configuration by creating a `.env` file in the root directory. See `.env.example` for available options.

**Important:** Change the JWT secret in production!

## Useful Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f mysql
```

### Rebuild containers after code changes
```bash
# Rebuild all
docker-compose up -d --build

# Rebuild specific service
docker-compose up -d --build backend
docker-compose up -d --build frontend
```

### Access MySQL database
```bash
docker exec -it vta-mysql mysql -u vta_user -pvta_password vta_dev
```

### Execute commands in containers
```bash
# Backend
docker exec -it vta-backend /bin/bash

# Frontend
docker exec -it vta-frontend /bin/sh
```

### Check service health
```bash
docker-compose ps
```

## Database Initialization

The database schema will be created automatically when the backend first connects to MySQL. The backend uses Entity Framework Core's `EnsureCreated()` or migrations to set up the database.

If you need to reset the database:
```bash
docker-compose down -v
docker-compose up -d
```

## Troubleshooting

### Backend can't connect to MySQL
- Ensure the MySQL container is healthy: `docker-compose ps`
- Check MySQL logs: `docker-compose logs mysql`
- The backend waits for MySQL health check before starting

### Frontend can't reach backend
- Update `Frontend/vta_app/assets/cfg/app_settings.json` to point to `http://localhost:5192/api/`
- Or access from host: `http://localhost:5192/api/`

### Permission issues with Assets folder
```bash
docker exec -it vta-backend chmod -R 777 /app/Assets
```

## Production Considerations

1. **Change default passwords** in `docker-compose.yml` or use a `.env` file
2. **Set a strong JWT secret** (minimum 32 characters)
3. **Use Docker secrets** for sensitive data
4. **Enable HTTPS** with reverse proxy (nginx/traefik)
5. **Set up persistent volumes** with proper backup strategy
6. **Review security settings** for MySQL and API
