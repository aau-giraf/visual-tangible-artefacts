# Architecture Overview

> Generated as part of **Step 5** from [plan.md](../plan.md).
> Synthesised from 9 feature docs, the dependency map, and direct source code inspection.

---

## Table of Contents

1. [Architecture Style](#1-architecture-style)
2. [System Diagram](#2-system-diagram)
3. [Layer Diagram](#3-layer-diagram)
4. [Navigation Structure (Flutter)](#4-navigation-structure-flutter)
5. [State Management](#5-state-management)
6. [Data Flow — End-to-End Example](#6-data-flow--end-to-end-example)
7. [Tech Debt Summary](#7-tech-debt-summary)
8. [Glossary](#8-glossary)

---

## 1. Architecture Style

**Multi-tier client-server with a real-time layer.**

The system has three independently deployed frontend/client applications that communicate with two backend services:

| Component | Technology | Role |
|-----------|-----------|------|
| **VTA.API** | ASP.NET Core 8 | REST API — auth, CRUD, file storage, TTS |
| **SyncService** | ASP.NET Core 8 + SignalR | Real-time hub — board collaboration, WebRTC signaling |
| **Flutter App** | Flutter 3.x (iOS, Android, Web) | Primary end-user client |
| **Admin Dashboard** | Vue 3 + Pinia + TypeScript | Admin-only web UI |
| **MySQL** | MySQL 8.0 | Shared relational database |
| **COTURN** | coturn | STUN/TURN server for WebRTC NAT traversal |

Key architectural characteristics:
- **Offline-first (Flutter):** Local SQLite database with bidirectional polling sync (30s interval)
- **Real-time (SignalR):** Persistent WebSocket connections for board state, session management, and WebRTC signaling
- **No backend service layer:** All 12 server-side entry points (11 controllers + 1 SignalR hub) inject the EF Core DbContext directly
- **No API gateway:** Both backend services are exposed directly; clients know both addresses

---

## 2. System Diagram

```mermaid
graph TB
    subgraph Clients
        Flutter["📱 Flutter App<br/>(iOS / Android / Web)"]
        Admin["🖥️ Admin Dashboard<br/>(Vue 3 SPA)"]
    end

    subgraph Backend["Backend Services"]
        API["VTA.API<br/>:5192 (REST)"]
        Sync["SyncService<br/>:5002 / :5133 (SignalR)"]
    end

    subgraph Infrastructure
        DB[(MySQL 8.0<br/>:3306)]
        TURN["COTURN<br/>:3478 (STUN/TURN)"]
        Assets["File System<br/>/app/Assets"]
        EL["ElevenLabs API<br/>(external)"]
    end

    Flutter -- "REST (JWT Bearer)" --> API
    Flutter -- "WebSocket (SignalR)" --> Sync
    Flutter -. "WebRTC (peer-to-peer)" .-> Flutter
    Flutter -- "STUN/TURN" --> TURN
    Flutter -- "TTS (direct, client-side)" --> EL
    Admin -- "REST (JWT Bearer)" --> API

    API --> DB
    API --> Assets
    API --> EL
    Sync --> DB

    style Flutter fill:#027DFD,color:#fff
    style Admin fill:#42b883,color:#fff
    style API fill:#512BD4,color:#fff
    style Sync fill:#512BD4,color:#fff
    style DB fill:#00758F,color:#fff
```

### Port Map (Docker Compose)

| Service | Container Port | Host Port | Protocol |
|---------|---------------|-----------|----------|
| VTA.API | 8080 | **5192** | HTTP (REST) |
| SyncService | 8080 | **5002** | HTTP (WebSocket/SignalR) |
| MySQL | 3306 | **3306** | MySQL |
| COTURN | 3478 | **3478** | UDP+TCP (STUN/TURN) |
| COTURN relay | 49160–49200 | 49160–49200 | UDP (media relay) |

> **Note:** In local development (non-Docker), `VTA.API` runs on `:5192` and `SyncService` on `:5133` (from `launchSettings.json`). Docker maps them to `:5192` and `:5002` respectively.

---

## 3. Layer Diagram

### Flutter App Layers

```mermaid
graph TB
    subgraph UI["UI Layer"]
        Screens["Screens<br/>(9 screens)"]
        Views["Views<br/>(4 views)"]
        Widgets["Widgets<br/>(~25 widgets)"]
    end

    subgraph Controllers["Controller Layer"]
        AuthC["AuthController"]
        ArtC["ArtefactController"]
        BoardC["ArtifactBoardController"]
        RemoteC["RemoteArtifactBoardController"]
        SettC["SettingsController"]
        ElevenC["ElevenLabsController"]
    end

    subgraph Services["Service Layer"]
        SignalR["SignalRService"]
        WebRTC["WebRTCService"]
        SyncS["SyncService"]
        SyncT["SyncTimer"]
        CallM["CallManager"]
        BoardL["BoardLayoutService"]
    end

    subgraph Data["Data Layer"]
        API["ApiProvider"]
        Repos["Repositories (8)"]
        DBH["DatabaseHelper"]
        SQLite[(Local SQLite)]
    end

    subgraph Singletons["Singletons (GetIt)"]
        Token["Token"]
        UserInfo["UserInfo"]
    end

    Screens --> Controllers
    Views --> Controllers
    Widgets --> Controllers
    Controllers --> Services
    Controllers --> Data
    Services --> Data
    Services --> Singletons
    Data --> SQLite
    Data --> Singletons

    style UI fill:#3498db,color:#fff
    style Controllers fill:#e67e22,color:#fff
    style Services fill:#2ecc71,color:#fff
    style Data fill:#9b59b6,color:#fff
    style Singletons fill:#95a5a6,color:#fff
```

### Backend Layers

```mermaid
graph TB
    subgraph HTTP["HTTP Layer"]
        Controllers["Controllers (11)"]
        Hub["BoardHub (SignalR)"]
    end

    subgraph Business["Business Logic<br/>(⚠️ inline in controllers)"]
        JWT["JWT Generation"]
        Hash["BCrypt Hashing"]
        ImgR["Image Resize"]
        SndC["Sound Conversion"]
        TTS["ElevenLabsService"]
    end

    subgraph Data["Data Layer"]
        EF["EF Core (VTAContext)"]
        FS["File System (/Assets)"]
    end

    subgraph Storage["Storage"]
        MySQL[(MySQL 8.0)]
        Disk["Disk (images, sounds)"]
    end

    Controllers --> Business
    Hub --> Business
    Business --> Data
    EF --> MySQL
    FS --> Disk

    style HTTP fill:#512BD4,color:#fff
    style Business fill:#e74c3c,color:#fff
    style Data fill:#9b59b6,color:#fff
```

> ⚠️ The "Business Logic" box is conceptual — these operations are **not** extracted into service classes. They run inline within controller action methods. See [dependency_map.md §4](dependency_map.md#4-backend-coupling).

---

## 4. Navigation Structure (Flutter)

The Flutter app uses imperative `Navigator.push` / named-route navigation (no declarative router).

```mermaid
flowchart TD
    Splash["SplashView<br/>/"]
    Login["LoginView<br/>/login"]
    Welcome["WelcomeScreen<br/>/welcome"]
    Board["ArtifactBoardScreen<br/>/boardview"]
    Settings["SettingsView<br/>/settings"]
    RemoteSession["RemoteSessionScreen<br/>/remote"]
    RemoteBoard["RemoteBoardScreen<br/>/remote-board"]
    Calling["CallingScreen<br/>/calling"]
    VideoCall["VideoCallScreen<br/>/video-call"]
    IncomingCall["IncomingCallScreen<br/>(pushed directly)"]

    Splash -- "has token?" --> Welcome
    Splash -- "no token" --> Login
    Login -- "login success" --> Welcome
    Welcome -- "tap board" --> Board
    Welcome -- "tap settings" --> Settings
    Welcome -- "join session" --> RemoteSession
    RemoteSession -- "session accepted" --> RemoteBoard
    RemoteSession -- "initiate call" --> Calling
    Calling -- "call accepted" --> VideoCall
    IncomingCall -- "accept" --> VideoCall
    Board -- "open settings" --> Settings
    RemoteBoard -- "start video call" --> VideoCall

    style Splash fill:#95a5a6,color:#fff
    style Login fill:#4a90d9,color:#fff
    style Welcome fill:#2ecc71,color:#fff
    style Board fill:#3498db,color:#fff
    style VideoCall fill:#e74c3c,color:#fff
```

### Entry Point

`main()` in `main.dart` initialises:
1. `GlobalConfiguration` from `assets/cfg/app_settings.json`
2. SQLite database (mobile only)
3. GetIt singletons: `Token`, `UserInfo`, `ApiProvider`, `ArtefactController`
4. Manual construction: `SettingsController`, `AuthController`
5. `CameraManager`, `NotificationService`
6. Legacy `Provider` state: `AuthState`, `ArtifactState`, `UserState`

Then runs `MyApp` with `initialRoute: SplashView.routeName`.

### Route Registration

All routes are defined in `MyApp.onGenerateRoute()` in `app.dart` using a `switch` statement — not a route table or declarative router. Routes: `/` (splash), `/login`, `/settings`, `/welcome`, `/boardview`, `/remote`, `/calling`, `/remote-board`, `/video-call`.

`IncomingCallScreen` is **not** registered as a named route — it's pushed directly by `CallManager` via `MyApp.navigatorKey.currentState!.push()`.

---

## 5. State Management

Three distinct patterns coexist in the Flutter app:

| Pattern | Used By | Scope |
|---------|---------|-------|
| **GetIt singletons** | `Token`, `UserInfo`, `ApiProvider`, `ArtefactController` | App-wide, registered in `main()` |
| **ChangeNotifier** (via `ListenableBuilder`) | `SettingsController`, `AuthController`, `ArtifactBoardController`, `RemoteArtifactBoardController`, `ElevenLabsController` | Feature-scoped, passed via constructors |
| **Provider** (legacy) | `AuthState`, `ArtifactState`, `UserState` | App-wide via `MultiProvider`, appears unused by main code paths |

### Backend State

| Component | State Mechanism |
|-----------|----------------|
| VTA.API | Stateless — JWT auth, no server-side sessions |
| SyncService (BoardHub) | **Static mutable collections** — 5 `Dictionary<>` fields + 1 `List<>` field (plain, not concurrent). In-memory only, lost on restart, not shared across instances |

### Admin Dashboard State

| Pattern | Used By |
|---------|---------|
| **Pinia store** | `useAuthStore` — holds JWT token, login/logout |
| **Axios interceptor** | Auto-injects Bearer token from auth store |
| **Component-local `ref()`** | Each view fetches its own data on mount |

---

## 6. Data Flow — End-to-End Example

**Scenario:** User creates an artefact with an image and sound, which later syncs to another device.

```mermaid
sequenceDiagram
    actor User
    participant UI as AddItemPopup (Flutter)
    participant AC as ArtefactController
    participant API as ApiProvider
    participant BE as ArtefactsController (Backend)
    participant FS as File System (/Assets)
    participant DB as MySQL
    participant Sync as SyncService (Flutter)
    participant SQLite as Local SQLite

    User->>UI: Fill name, pick image, record sound
    UI->>AC: createArtefact(name, image, sound, categoryId)
    AC->>API: POST /api/Artefacts (multipart/form-data)
    API->>BE: [Authorize] → extract userId from JWT

    BE->>BE: ImageUtilities.ResizeImage(image, 200x200)
    BE->>FS: Save image → /Assets/Artefacts/{guid}.webp
    BE->>BE: SoundUtilities.ConvertToM4a(sound)
    BE->>FS: Save sound → /Assets/Sounds/{guid}.m4a
    BE->>DB: INSERT Artefact (name, imagePath, soundPath, userId, modifiedDate)
    BE-->>API: 201 Created {artefact JSON}
    API-->>AC: Artefact DTO
    AC->>AC: notifyListeners() → UI rebuilds

    Note over Sync: 30 seconds later...

    Sync->>API: GET /api/Sync/changes?since={lastSync}
    API->>BE: SyncController.GetChanges()
    BE->>DB: SELECT WHERE modifiedDate > since
    BE-->>Sync: SyncResponseDTO [{artefact}]
    Sync->>API: GET /api/assets/artefacts/{guid}.webp
    Sync->>API: GET /api/assets/sounds/{guid}.m4a
    Sync->>SQLite: INSERT artefact + local file paths
    Sync->>SQLite: UPDATE sync_metadata (lastSyncDate = now)
```

---

## 7. Tech Debt Summary

Aggregated from all per-feature architectural concerns and the dependency map. See [improvement_proposals.md](../improvement_proposals.md) for full remediation proposals.

### By Category

| Category | Count | Severity Distribution | Key Examples |
|----------|-------|-----------------------|-------------|
| **God classes** | 7 | 7× 🔴 | `RemoteArtifactBoardController` (1,209 LOC), `SyncService` (1,009 LOC) |
| **Missing abstractions** | 3 | 3× 🔴 | No backend service layer, no repository interfaces, no event bus |
| **Duplicated logic** | 4 | 2× 🔴 2× 🟠 | Pairing CRUD, contacts endpoint, user deletion, dual TTS path |
| **Security** | 4 | 2× 🔴 2× 🟠 | Mock auth bypass, API key on client, hardcoded TURN creds, JWT secret in config |
| **Circular dependencies** | 3 | 1× 🔴 2× 🟠 | Collab ↔ Board (compile-time), Auth ↔ Sync, Auth ↔ Collab |
| **Scalability** | 4 | 1× 🔴 3× 🟡 | BoardHub static state, no pagination, no sync backoff, no transactions |
| **DI / Coupling** | 4 | 1× 🟠 3× 🟡 | 4 singleton patterns, `CallManager` → `MyApp`, AuthController orchestration bottleneck |
| **Logging** | 3 | 1× 🟠 2× 🟡 | `Console.WriteLine` in production, `print()` everywhere, empty catch blocks |
| **Incomplete features** | 3 | 3× 🟡 | `themeMode()` stub, localization commented out, profile pic not synced |

### Priority Summary (from improvement_proposals.md)

| Priority | What | Effort |
|----------|------|--------|
| **P0 — Now** | Mock auth bypass, API key on client, orphaned assets on admin delete, BoardHub static state | Small–Medium |
| **P1 — Next Sprint** | Backend service layer, god class splits, duplicate logic consolidation | Large |
| **P2 — Soon** | Pagination, sync reliability (backoff, retry, transactions), structured logging | Medium |
| **P3 — Backlog** | Token refresh, DI consistency, state management consolidation, profile picture sync | Medium–Large |

---

## 8. Glossary

| Term | Definition |
|------|-----------|
| **Artefact** | A visual/audio item (image + optional sound + name) belonging to a user. The primary content unit. Stored in `Artefacts` table + `/Assets/` filesystem. |
| **Board** | A layout container for artefacts. Two types exist: TalkingMat (grid) and LinearBoard (horizontal strip). Stored in `SavedBoards` table. |
| **SavedArtefact** | A placement record linking an artefact to a board at a specific position (X, Y, scale, rotation). Stored in `SavedArtefacts` table. |
| **Category** | A grouping for artefacts, each with a name and optional image. Users have default categories. |
| **TalkingMat** | A board type where artefacts are arranged in a free-form grid layout. |
| **LinearBoard** | A board type where artefacts are arranged in a horizontal strip with a configurable number of slots (`FieldCount`). |
| **Relation** | A caregiver-child pairing stored in `Relations` table. Has an `IsActive` flag for soft-delete. |
| **Session** | A real-time collaboration session managed by `BoardHub`. Two users share a board view over SignalR. |
| **BoardHub** | The SignalR hub (`SyncService`) managing sessions, board state sync, and WebRTC signal relay. |
| **TURN** | Traversal Using Relays around NAT — the relay protocol used when peer-to-peer WebRTC connections fail. Provided by COTURN. |
| **Caregiver** | A user with role `Caregiver` who manages one or more children and can initiate sessions. |
| **Child** | A user with role `Child` who uses boards/artefacts and receives session invitations from caregivers. |
| **Admin** | A user with role `Admin` who manages users and pairings via the admin dashboard. |
| **FieldCount** | User setting controlling how many artefact slots appear in a LinearBoard (default: 4, options: 2/4/6/8). |
| **NameVisible** | User setting controlling whether artefact names are shown under images (maps to `textUnderImages` in Flutter). |
| **SyncTimer** | A Flutter singleton that fires `SyncService.autoSync()` every 30 seconds to keep the local SQLite database in sync with the backend. |
| **GetIt** | The service locator / dependency injection container used in the Flutter app. |
| **Pinia** | The state management library used in the Vue 3 admin dashboard. |
