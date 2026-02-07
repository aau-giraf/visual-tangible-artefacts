# Feature: Admin Panel

## Summary

The Admin Panel is a **Vue 3 + Pinia** single-page application (`Frontend/admin-dashboard/`) that provides administrators with user management capabilities. It communicates exclusively with the backend's **`AdminController`** (guarded by `[Authorize(Roles = "Admin")]`) and **`RelationController`** (also admin-only) for managing caregivers, children, admins, and caregiver-child pairings. The dashboard has 6 views behind a `DashboardLayout` (sidebar + header): Overview, Users, Children, Caregivers, Pairings, and Admins. Each view has a corresponding API module in `src/api/` that calls the backend through a shared Axios instance with a Bearer token interceptor. The Flutter app has no admin functionality — this is a separate web-only tool.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class AdminController {
            +GetCaregivers() ActionResult~List~UserGetDTO~~
            +GetChildren() ActionResult~List~UserGetDTO~~
            +GetAdmins() ActionResult~List~UserGetDTO~~
            +CreateAdmin(UserSignupDTO) ActionResult~UserGetDTO~
            +DeleteUser(id) IActionResult
            +MakeUserAdmin(id) IActionResult
            +GetPairings() ActionResult~List~object~~
            +CreatePairing(CreatePairingRequest) ActionResult
            +DeletePairing(id) IActionResult
        }
        class RelationController {
            +GetPairings() ActionResult~List~PairingDTO~~
            +GetPairingsForCaregiver(caregiverId) ActionResult~List~PairingDTO~~
            +CreatePairing(CreatePairingDTO) ActionResult~PairingDTO~
            +RemovePairing(id) IActionResult
            +RemovePairingByIds(CreatePairingDTO) IActionResult
        }
    }

    %% ── Admin Dashboard ──────────────────────────
    namespace AdminDashboard {
        class OverviewView {
            «Vue Component»
        }
        class UsersView {
            «Vue Component»
        }
        class ChildrenView {
            «Vue Component»
        }
        class CaregiversView {
            «Vue Component»
        }
        class PairingsView {
            «Vue Component»
        }
        class AdminsView {
            «Vue Component»
        }
        class apiAdmins["api/admins.ts"] {
            +getAdmins() Promise
            +createAdmin(data) Promise
            +deleteAdmin(id) Promise
        }
        class apiCaregivers["api/caregivers.ts"] {
            +getCaregivers() Promise
        }
        class apiChildren["api/children.ts"] {
            +getChildren() Promise
        }
        class apiPairings["api/pairings.ts"] {
            +getPairings() Promise
            +createPairing(data) Promise
            +deletePairing(id) Promise
        }
        class apiUsers["api/users.ts"] {
            +getUsers() Promise
            +deleteUser(id) Promise
            +makeAdmin(id) Promise
        }
        class apiAxios["api/axios.ts"] {
            +apiClient AxiosInstance
            +requestInterceptor (Bearer token)
        }
    }

    %% ── Relationships ────────────────────────────
    OverviewView --> apiUsers : fetches stats
    UsersView --> apiUsers : CRUD
    ChildrenView --> apiChildren : list
    CaregiversView --> apiCaregivers : list
    PairingsView --> apiPairings : CRUD
    AdminsView --> apiAdmins : CRUD

    apiAdmins --> apiAxios : uses
    apiCaregivers --> apiAxios : uses
    apiChildren --> apiAxios : uses
    apiPairings --> apiAxios : uses
    apiUsers --> apiAxios : uses

    apiAxios ..> AdminController : HTTP (Admin endpoints)
    apiPairings ..> RelationController : HTTP (Relation endpoints)
```

---

## Sequence Diagram — Admin Creates Caregiver-Child Pairing

```mermaid
sequenceDiagram
    actor Admin
    participant PV as PairingsView.vue
    participant API as api/pairings.ts
    participant Axios as Axios (interceptor)
    participant AC as AdminController (Backend)
    participant DB as MySQL (Relations)

    Admin->>PV: Select caregiver + child, click "Create Pairing"
    PV->>API: createPairing({caregiverId, childId})
    API->>Axios: POST /api/Admin/pairings
    Axios->>Axios: Inject Bearer token from authStore
    Axios->>AC: POST /api/Admin/pairings
    AC->>AC: Validate caregiver role, child role
    AC->>DB: Check existing active pairing
    alt Pairing exists
        AC-->>Axios: 409 Conflict
        Axios-->>API: Error
        API-->>PV: Show error
    else New pairing
        AC->>DB: INSERT Relation(caregiverId, childId, isActive=true)
        DB-->>AC: OK
        AC-->>Axios: 200 {message, id}
        Axios-->>API: Response
        API-->>PV: Success
        PV->>PV: Refresh pairings list
    end
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **Duplicate pairing CRUD** | 🔴 Critical | Both `AdminController` (at `/api/Admin/pairings`) and `RelationController` (at `/api/Relation`) implement pairing CRUD with slightly different logic: Admin filters by `IsActive`, Relation returns all; different DTO shapes (anonymous object vs `PairingDTO`); different validation. **Consolidate into one controller** — likely `RelationController` with proper DTOs. |
| 2 | ~~**Mock auth bypass in production code**~~ | ✅ Resolved | Fixed in Phase 1.3 — mock token block deleted from `store/auth.ts`. Real API login now executes. |
| 3 | ~~**AdminController.DeleteUser doesn't clean up**~~ | ✅ Resolved | Fixed in Phase 1.4 — both controllers now use shared `UserCleanupHelper.DeleteUserWithAssets()` for cascade cleanup. |
| 4 | **No admin read access to content** | 🟡 Medium | Admins can manage users and pairings but cannot view artefacts, boards, or session history. For a complete admin tool, add read-only views for user content and session analytics. |
| 5 | **Anonymous DTO in AdminController.GetPairings** | 🟡 Medium | Returns `Select(p => new { ... })` instead of a proper DTO, while `RelationController` uses `PairingDTO`. Use consistent DTO types. |
| 6 | **No pagination** | 🟡 Medium | All list endpoints (`GetCaregivers`, `GetChildren`, etc.) return all records with no pagination. Will be a problem at scale. |
| 7 | **Hardcoded baseURL** | 🟡 Medium | `api/axios.ts` has `baseURL: 'https://vta.syncr.dev/api/'`. Should use an environment variable (`import.meta.env.VITE_API_URL`). |
