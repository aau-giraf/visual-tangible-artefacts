# Feature: Authentication

## Summary

Authentication spans all three stacks. The backend **`UsersController`** exposes `POST /api/Users/Login` and `POST /api/Users/SignUp` endpoints that validate credentials with BCrypt and issue HS256-signed JWTs (30-day expiry, issuer `api.vta.com`). The Flutter app wraps these calls in **`AuthModel`** (HTTP + caching via `SharedPreferences`) and **`AuthController`** (orchestrates login side-effects: sync timer, SignalR connection, call-manager setup, and navigation). The admin dashboard uses a Pinia **`useAuthStore`** backed by **`api/auth.ts`** (Axios POST), with `localStorage` token persistence and a Vue Router navigation guard (`meta.requiresAuth`). Both clients send the JWT as a `Bearer` header on all subsequent requests — the Flutter app via `ApiProvider`, the admin via an Axios request interceptor.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction LR

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class UsersController {
            +Login(UserLoginDTO) ActionResult~UserLoginResponseDTO~
            +SignUp(UserSignupDTO) ActionResult~UserLoginResponseDTO~
            +GetUsers() ActionResult~List~UserGetDTO~~
            +GetUser(id) ActionResult~UserGetDTO~
            +GetRelatedContacts() ActionResult~List~UserGetDTO~~
            +PutUser(id, User) IActionResult
            +PatchUser(UserPatchDTO) IActionResult
            +DeleteUser(id) IActionResult
            -GenerateJwt(User) string
        }
        class UserLoginDTO {
            +string Username
            +string Password
        }
        class UserLoginResponseDTO {
            +string Token
            +string userId
        }
        class UserSignupDTO {
            +string Username
            +string Password
            +string Name
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class AuthModel {
            +checkAuth() Future~bool~
            +login(username, password) Future~void~
            +signup(SignupForm) Future~void~
            +logout() Future~void~
            +getUser(userId) Future~User?~
            +loadCache() Future~void~
            +cacheData(token?, userId?) Future~void~
            +clearCacheData() Future~void~
        }
        class AuthController {
            +checkAuth(context?) Future~bool~
            +login(username, password, context?) Future~void~
            +signup(username, password, name, context?) Future~void~
            +logout(context?) Future~void~
            +getCurrentUser() Future~User?~
        }
        class Token {
            +String? value
        }
        class UserInfo {
            +String? userId
        }
    }

    %% ── Admin Dashboard ──────────────────────────
    namespace AdminDashboard {
        class useAuthStore {
            +token Ref~string~
            +user Ref~object~
            +isAuthenticated Ref~bool~
            +login(UserLoginDTO) Promise~void~
            +logout() void
        }
        class authApi {
            +login(UserLoginDTO) Promise~UserLoginResponseDTO~
        }
        class axiosInterceptor {
            +injectBearerToken(config) config
        }
        class routerGuard {
            +beforeEach(to, from, next) void
        }
    }

    %% ── Relationships ────────────────────────────
    AuthController --> AuthModel : delegates to
    AuthModel --> Token : writes token
    AuthModel --> UserInfo : writes userId
    AuthModel ..> UsersController : HTTP POST /Login, /SignUp
    AuthController --> SyncTimer : starts on login
    AuthController --> SignalRService : connects on login
    AuthController --> CallManager : setupCallbacks

    useAuthStore --> authApi : calls login()
    authApi ..> UsersController : HTTP POST /Login
    axiosInterceptor --> useAuthStore : reads token
    routerGuard --> useAuthStore : checks isAuthenticated
```

---

## Sequence Diagram — Login Flow (Flutter)

```mermaid
sequenceDiagram
    actor User
    participant LoginView as LoginView (Flutter)
    participant AC as AuthController
    participant AM as AuthModel
    participant AP as ApiProvider
    participant UC as UsersController (Backend)
    participant DB as MySQL (Users)
    participant SP as SharedPreferences

    User->>LoginView: Enter username + password
    LoginView->>AC: login(username, password, context)
    AC->>AM: login(username, password)
    AM->>AP: postAsJson("Users/Login", {username, password})
    AP->>UC: POST /api/Users/Login
    UC->>DB: Find user by username
    DB-->>UC: User record
    UC->>UC: BCrypt.Verify(password, hash)
    UC->>UC: GenerateJwt(user) — HS256, 30-day expiry
    UC-->>AP: 200 {token, userId}
    AP-->>AM: Response
    AM->>SP: cache jwtToken + userId
    AM->>Token: set value = token
    AM->>UserInfo: set userId = id
    AM-->>AC: success
    AC->>AC: artifactController.updateArtifacts()
    AC->>AC: SignalRService().connect(userId)
    AC->>AC: SignalRService().loadContacts(token)
    AC->>AC: CallManager().setupCallbacks()
    AC->>AC: SyncTimer().start()
    AC->>AC: Check user role
    alt Caregiver
        AC->>LoginView: Navigate → RemoteSessionScreen
    else Child
        AC->>LoginView: Navigate → WelcomeScreen
    end
```

---

## Sequence Diagram — Login Flow (Admin Dashboard)

```mermaid
sequenceDiagram
    actor Admin
    participant LV as LoginView.vue
    participant Store as useAuthStore (Pinia)
    participant API as api/auth.ts
    participant Axios as Axios (interceptor)
    participant UC as UsersController (Backend)

    Admin->>LV: Enter username + password
    LV->>Store: login({username, password})
    Store->>API: login(credentials)
    API->>Axios: POST /Users/Login
    Axios->>UC: POST /api/Users/Login
    UC-->>Axios: 200 {token, userId}
    Axios-->>API: response.data
    API-->>Store: {token, userId}
    Store->>Store: token.value = token
    Store->>Store: localStorage.setItem("token", token)
    Store->>Store: isAuthenticated = true
    Store->>Store: router.push("/dashboard")
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **Mock auth bypass in admin store** | 🔴 Critical | `store/auth.ts` has a hardcoded `token.value = 'local-mock-token'` block with a `return` before the real API call. Any push with this block uncommented means the admin panel accepts *any* credentials. This should be behind an `import.meta.env.DEV` guard or removed entirely. |
| 2 | **30-day JWT with no refresh** | 🟠 High | Tokens expire after 30 days with no refresh-token mechanism. If a token is stolen, it's valid for a month. Consider short-lived access tokens (15–60 min) + a refresh token stored in an HttpOnly cookie. |
| 3 | **AuthController tightly coupled to screens** | 🟠 High | `AuthController` imports `WelcomeScreen`, `ArtifactBoardScreen`, `RemoteSessionScreen`, `LoginView` for navigation. A controller should not depend on UI widgets — inject a navigation callback or use a router service instead. |
| 4 | **No role enforcement on backend** | 🟡 Medium | `UsersController` only checks `[Authorize]` (valid JWT). Admin-specific endpoints (e.g., `GetUsers`) lack `[Authorize(Roles = "Admin")]`. Any authenticated user can list all users. |
| 5 | **UsersController is a god class** | 🟡 Medium | 458 lines handling login, signup, CRUD, settings (PATCH), contacts, and JWT generation. Split into `AuthController` (login/signup/JWT) and `UsersController` (CRUD/settings). |
| 6 | **Custom JWT claims** | 🟡 Medium | Uses `"id"` and `"role"` as custom claim strings instead of `ClaimTypes.NameIdentifier` / `ClaimTypes.Role`. Works, but non-standard and requires `MapInboundClaims = false` to avoid mapping issues. |
| 7 | **Duplicate auth-check code path** | 🟡 Medium | `functions/auth.dart` (`AuthPage`) implements a parallel auth-check flow using `Provider` (`AuthState`, `ArtifactState`, `UserState`) that doesn't use `AuthController` at all — appears to be dead/legacy code. |
| 8 | **Duplicated login side-effects** | 🟡 Medium | `AuthController.login()` and `AuthController.checkAuth()` both contain near-identical blocks: connect SignalR → load contacts → setup callbacks. Extract a `_initializePostAuthServices()` helper. |
