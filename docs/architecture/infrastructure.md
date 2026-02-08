# Infrastructure

> How VTA is built, deployed and wired together at the container / network / database level.

---

## 1  Deployment Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                    docker-compose  (vta-network, bridge)        │
│                                                                 │
│  ┌───────────┐   ┌──────────────┐   ┌──────────────┐           │
│  │  mysql     │   │  backend     │   │ syncservice  │           │
│  │  :3306     │◄──│  :8080       │   │  :8080       │           │
│  │  (MySQL 8) │   │  (VTA.API)   │   │  (SignalR)   │           │
│  └───────────┘   └──────┬───────┘   └──────┬───────┘           │
│        ▲                 │                  │                   │
│        └────depends_on───┘──────────────────┘                   │
│                                                                 │
│  ┌─────────────┐                                                │
│  │  coturn      │                                               │
│  │  :3478       │  (STUN / TURN relay)                          │
│  └─────────────┘                                                │
│                                                                 │
│  # frontend (commented out — run locally during development)    │
│  # :80  nginx + Flutter web                                     │
└─────────────────────────────────────────────────────────────────┘

Exposed host ports:
  3306  → mysql
  5192  → backend  (VTA.API)
  5002  → syncservice
  3478  → coturn (UDP+TCP)
  49160-49200 → coturn media relay (UDP)
```

---

## 2  Docker Compose Services

Source: `docker-compose.yml`

### 2.1  mysql

| Property | Value |
|----------|-------|
| Image | `mysql:8.0` |
| Container | `vta-mysql` |
| Restart | `unless-stopped` |
| Port | 3306:3306 |
| Volume | `mysql_data:/var/lib/mysql` |
| Health-check | `mysqladmin ping` every 10 s, 5 retries |

Environment variables:

| Var | Value |
|-----|-------|
| `MYSQL_ROOT_PASSWORD` | `root_password` |
| `MYSQL_DATABASE` | `vta_dev` |
| `MYSQL_USER` | `vta_user` |
| `MYSQL_PASSWORD` | `vta_password` |

### 2.2  backend (VTA.API)

| Property | Value |
|----------|-------|
| Dockerfile | `Backend/VTA.API/Dockerfile` |
| Build context | `./Backend` |
| Container | `vta-backend` |
| Port | 5192 → 8080 |
| Volume | `backend_assets:/app/Assets` |
| Depends on | mysql (healthy) |

Environment variables:

| Var | Value |
|-----|-------|
| `ASPNETCORE_ENVIRONMENT` | `Development` |
| `ASPNETCORE_URLS` | `http://+:8080` |
| `ConnectionStrings__DefaultConnection` | `server=mysql;port=3306;database=vta_dev;user=vta_user;password=vta_password` |
| `Secret__SecretKey` | `your-secret-key-change-this-in-production-minimum-32-characters-long` |
| `AUTO_CREATE_DATABASE` | `true` |

### 2.3  syncservice

| Property | Value |
|----------|-------|
| Dockerfile | `Backend/SyncService/Dockerfile` |
| Build context | `./Backend` |
| Container | `vta-syncservice` |
| Port | 5002 → 8080 |
| Volume | `backend_assets:/app/Assets` (shared with backend) |
| Depends on | mysql (healthy) |

Same JWT secret and connection string as `backend`.

### 2.4  coturn

| Property | Value |
|----------|-------|
| Image | `coturn/coturn:latest` |
| Container | `coturn-local` |
| Ports | 3478 (UDP+TCP), 49160-49200 (UDP) |
| Config file | `turnserver.local.conf` mounted to `/etc/coturn/` |

### 2.5  frontend (commented out)

Would build from `Frontend/vta_app/Dockerfile`, mapping port 8080→80. Currently disabled — Flutter app is run locally during development or deployed separately.

### Shared Resources

| Resource | Type | Used By |
|----------|------|---------|
| `mysql_data` | named volume | mysql |
| `backend_assets` | named volume | backend, syncservice |
| `vta-network` | bridge network | all 4 services |

---

## 3  Dockerfiles

### 3.1  VTA.API  (`Backend/VTA.API/Dockerfile`)

Three-stage multi-stage build:

| Stage | Base Image | Purpose |
|-------|-----------|---------|
| `build` | `mcr.microsoft.com/dotnet/sdk:8.0` | Restore + build (`dotnet restore`, `dotnet build -c Release`) |
| `publish` | (continues from `build`) | `dotnet publish -c Release` |
| `final` | `mcr.microsoft.com/dotnet/aspnet:8.0` | Runtime — creates `/app/Assets/Categories` and `/app/Assets/Artefacts` directories |

Copies both `VTA.API.csproj` and `VTA.Data.csproj` for dependency resolution.

### 3.2  SyncService  (`Backend/SyncService/Dockerfile`)

Same three-stage pattern as VTA.API. Also copies `VTA.Data.csproj`. Does **not** create Assets directories (asset storage accessed via shared volume only).

### 3.3  Flutter Web  (`Frontend/vta_app/Dockerfile`)

| Stage | Base Image | Purpose |
|-------|-----------|---------|
| `build` | `ghcr.io/cirruslabs/flutter:3.24.3` | `flutter pub get` + `flutter build web --release` |
| runtime | `nginx:alpine` | Serve static SPA from `/usr/share/nginx/html` |

Copies custom `nginx.conf` into the container.

---

## 4  COTURN Configuration

Two config files ship with the repo — one for local development, one for production.

### 4.1  Local  (`turnserver.local.conf`)

| Setting | Value |
|---------|-------|
| Realm | `localhost` |
| Listening port | 3478 |
| Relay port range | 49160–49200 |
| Relay IP | `127.0.0.1` |
| Credentials | `testuser:testpass` (static) |
| TLS | disabled (`no-tls`, `no-dtls`) |
| Loopback | `allow-loopback-peers` enabled |
| Verbose | enabled |

### 4.2  Server  (`turnserver.server.conf`)

| Setting | Value |
|---------|-------|
| Realm | `syncr.dev` |
| Server name | `turn.syncr.dev` |
| Listening port | 3478 |
| Relay port range | 49160–49200 |
| External IP | `85.27.190.158 / 192.168.0.187` (NAT mapping) |
| Credentials | `turnuser:strongpassword` (static) |
| TLS | commented out (cert paths present but disabled) |
| Log file | `/var/log/coturn/turnserver.log` |
| CLI password | `clipassword` |

> **Note:** Both configs use static long-term credentials. The production config has TLS certificate paths but they are commented out.

---

## 5  Database Schemas

### 5.1  MySQL  (`mysql_schema.sql`)

Server-side canonical schema. Database: `dev_vta`, charset `utf8mb4`, collation `utf8mb4_0900_ai_ci`.

#### Tables

| Table | PK | Key Columns | Notes |
|-------|-----|-------------|-------|
| `user` | `id` (VARCHAR 36) | `username`, `password`, `guardianKey`, `nameVisible`, `fieldCount` | Guardian key for caregiver pairing |
| `category` | `categoryId` (VARCHAR 36) | `userId` FK → user, `categoryIndex`, `imagePath`, `usageCount`, `lastUsedDate` | Seeded row: `Session-Artefact` (system category) |
| `artefact` | `artefactId` (VARCHAR 36) | `userID` FK → user, `categoryId` FK → category, `imagePath`, `soundPath`, `nameShown` | Cascading deletes from both user and category |
| `savedBoard` | `id` (VARCHAR 36) | `userId` FK → user, `savedArtefactIds` (JSON), `artefactIds` (JSON), `snapshotPath` | Board layout stored as JSON arrays |
| `savedArtefact` | `id` (VARCHAR 36) | `artefactId` FK → artefact, `boardId` FK → savedBoard, `posX`, `posY`, `width`, `height`, `nameVisible` | Per-board artefact placement |

#### Indexes

| Index | Columns | Purpose |
|-------|---------|---------|
| `idx_user_username` | `user.username` | Login lookups |
| `idx_category_userid_index` | `category(userId, categoryIndex)` | Category listing per user |
| `idx_artefact_userid_categoryid` | `artefact(userID, categoryId)` | Artefact filtering |
| `idx_artefact_index` | `artefact.artefactIndex` | Ordering |

#### Foreign Key Strategy

All FKs use `ON DELETE CASCADE ON UPDATE CASCADE`. Deleting a user cascades through categories → artefacts → savedArtefacts → savedBoards.

### 5.2  SQLite  (`SQLite_schema.sql`)

Client-side (Flutter) offline schema. Uses snake_case naming, INTEGER for booleans, unix-epoch timestamps, and soft-delete via `is_deleted` columns.

#### Tables

| Table | PK | Key Columns | Notes |
|-------|-----|-------------|-------|
| `user` | `id` (TEXT) | `username`, `password`, `guardian_key`, `is_deleted` | Mirrors server `user` |
| `category` | `category_id` (TEXT) | `user_id`, `category_index`, `image_path`, `is_deleted` | Mirrors server `category` |
| `artefact` | `artefact_id` (TEXT) | `user_id`, `category_id`, `image_path`, `sound_path`, `is_deleted` | Mirrors server `artefact` |
| `saved_board` | `id` (TEXT) | `user_id`, `saved_artefact_ids` (TEXT/JSON), `artefact_ids` (TEXT/JSON), `is_deleted` | Mirrors server `savedBoard` |
| `saved_artefact` | `id` (TEXT) | `artefact_id`, `board_id`, `pos_x`, `pos_y`, `width`, `height`, `is_deleted` | Mirrors server `savedArtefact` |
| `session_meta` | `id` (TEXT) | `name`, `created_at`, `updated_at` | Local-only session tracking |

> **Schema divergence:** The SQLite schema adds `is_deleted` (soft-delete) and `sync_status` columns not present in MySQL. The MySQL schema uses `DATETIME`; SQLite uses INTEGER unix timestamps. Column naming differs (camelCase vs snake_case).

---

## 6  nginx Configuration  (`Frontend/vta_app/nginx.conf`)

Used inside the Flutter web Docker container.

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # SPA routing — fallback to index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Gzip compression
    gzip on;
    gzip_types text/plain application/javascript text/css application/json;

    # Static asset caching (1 year, immutable)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

Key behaviour:
- **SPA fallback:** All unknown routes serve `index.html` (Flutter handles routing client-side).
- **Gzip:** Enabled for text, JS, CSS, JSON.
- **Cache:** Static assets get 1-year `Cache-Control: public, immutable`.

---

## 7  Environment & Secrets

| Secret | Where Configured | Current Value |
|--------|-----------------|---------------|
| MySQL root password | `docker-compose.yml` | `root_password` |
| MySQL user password | `docker-compose.yml` | `vta_password` |
| JWT secret key | `docker-compose.yml` + `appsettings.json` | `your-secret-key-change-this-in-production-minimum-32-characters-long` |
| JWT issuer / audience | `appsettings.json` (SyncService) | `api.vta.com` / `user.vta.com` |
| TURN credentials (local) | `turnserver.local.conf` | `testuser:testpass` |
| TURN credentials (server) | `turnserver.server.conf` | `turnuser:strongpassword` |
| COTURN CLI password | `turnserver.server.conf` | `clipassword` |

> ⚠️ **All secrets are committed as plaintext in the repository.** See [improvement_proposals.md](../improvement_proposals.md) §8 for recommendations on secret management.

---

## 8  Cross-References

| Topic | Link |
|-------|------|
| Architecture overview | [overview.md](overview.md) |
| Dependency map | [dependency_map.md](dependency_map.md) |
| Data sync feature | [data_sync.md](../features/data_sync.md) |
| Real-time collaboration | [realtime_collaboration.md](../features/realtime_collaboration.md) |
| Video calling (uses COTURN) | [video_calling.md](../features/video_calling.md) |
| Improvement proposals | [improvement_proposals.md](../improvement_proposals.md) |
