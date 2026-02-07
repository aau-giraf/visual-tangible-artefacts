# VTA Documentation Plan & Progress

> Audited 2025-02-07. This is the single source of truth.

## Goal

Systematically document every class/component in the VTA monorepo, then synthesize feature-level and architecture-level docs. Methodology follows `codebase-documentation-guide.md`.

## Scope

| Component | Source Files | Documented | Remaining |
|-----------|-------------|------------|-----------|
| Backend (.NET) | 54 | 44 | 10 (tests) |
| Flutter | 119 | 18 | 101 |
| Admin Dashboard | 29 | 0 | 29 |
| **Total** | **202** | **62** | **140** |

Output: `docs/classes/{backend,flutter,admin}/*.md` per-class cards, plus feature diagrams and architecture docs.

---

## Step 2: Per-Class Documentation

Work one folder at a time. Use `/clear` between folders.

### Phase A: Backend VTA.Data — DONE
- [x] Models/ (9 files)
- [x] DbContexts/ (8 files)
- [x] Extensions/ (1 file)

### Phase B: Backend VTA.API — DONE
- [x] DTOs/ (9 files)
- [x] Utilities/ (5 files)
- [x] Extensions/ (1 file)
- [x] Controllers/ (11 files)
- [x] Program.cs (1 file)

### Phase C: Backend SyncService — DONE
- [x] Models/ (6 files)
- [x] Hubs/BoardHub (1 file)
- [x] Program.cs (1 file)

### Phase D: Flutter Database Layer
- [x] database/models/ (7 files)
- [x] database/repositories/ (8 files)
- [x] database/ root (3 files)
- [ ] database/mappers/ (1 file)

### Phase E: Flutter Models & DTOs
- [ ] modelsDTOs/ (9 files)
- [ ] models/ (5 files)

### Phase F: Flutter Utilities & Singletons
- [ ] singletons/ (2 files)
- [ ] utilities/api/ (2-3 files)
- [ ] utilities/audio/ (6 files)
- [ ] utilities/config/ (2 files)
- [ ] utilities/data/ (2 files)
- [ ] utilities/ remaining (~3 files)

### Phase G: Flutter Services
- [ ] services/ pass 1: sync_service, sync_timer, remote_sync_service, board_layout_service, relation_service, notification_service
- [ ] services/ pass 2: signalr_service, webrtc_service, call_manager, video_call_manager

### Phase H: Flutter Controllers
- [ ] controllers/ (8 files)

### Phase I: Flutter UI Widgets
- [ ] widgets/board/ (11 files)
- [ ] widgets/categories/ (5 files)
- [ ] widgets/online_session/ + video/ + utilities/ + TTS (~5 files)

### Phase J: Flutter UI Screens & Views
- [ ] screens/ pass 1 (6 files)
- [ ] screens/ pass 2 (6 files)
- [ ] views/ (4 files)

### Phase K: Flutter Remaining
- [ ] settings/ (3 files)
- [ ] notifiers/ + shared/ + functions/ + localization/ (~7 files)
- [ ] lib/ root + theme/ (~4 files)

### Phase L: Admin Dashboard
- [ ] interfaces/ (8 files)
- [ ] api/ (7 files)
- [ ] store/ + router/ (2 files)
- [ ] views/ (7 files)
- [ ] layouts/ + components/ + root (5 files)

### Phase M: Tests
- [ ] VTA.Tests/ (8 files)
- [ ] SyncService.Tests/ (3 files)
- [ ] Flutter test/ + integration_test/ (~4 files)

### Phase N: Infrastructure
- [ ] Docker, CI/CD, DB schemas, TURN config

---

## Step 3: Feature Diagrams

Mermaid class + sequence diagrams per feature, cross-stack.

- [ ] Authentication
- [ ] Artifact Management
- [ ] Board System
- [ ] Real-time Collaboration
- [ ] Video Calling
- [ ] Text-to-Speech
- [ ] Admin Panel
- [ ] Data Sync
- [ ] Settings & User Management

## Step 4: Dependency Map
- [ ] docs/architecture/dependency_map.md

## Step 5: Architecture Overview
- [ ] docs/architecture/overview.md

## Step 6: Master Index
- [ ] docs/_index.md
