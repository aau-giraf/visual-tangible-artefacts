# AuthController

**File:** `Frontend/vta_app/lib/src/controllers/auth_controller.dart` (230 lines)

## Purpose

ChangeNotifier managing authentication lifecycle: login, signup, logout, and session restoration. Bridges auth state to SignalR connection and role-based navigation.

## Class: `AuthController` extends `ChangeNotifier`

### Constructor
`AuthController(AuthModel model)` — also resolves `ArtefactController` from GetIt.

### Methods

| Method | Description |
|--------|-------------|
| `checkAuth({context})` | Checks for stored JWT → loads cache → starts `SyncTimer` → connects SignalR + loads contacts + sets up `CallManager` |
| `login(username, password, {context})` | Authenticates → fetches artefacts/categories → connects SignalR → navigates based on role |
| `signup(username, password, name, {context})` | Creates account via `SignupForm` → navigates to login (does NOT auto-login) |
| `logout(context)` | Shows confirmation dialog → clears CallManager callbacks → disconnects SignalR → clears user data → navigates to login |
| `getCurrentUser()` | Returns `User?` for stored userId |

### Login Navigation
- **Caregiver** (`UserRole.caregiver`) → `RemoteSessionScreen`
- **All other roles** → `WelcomeScreen`

### SignalR Setup (duplicated in `checkAuth` and `login`)
1. `SignalRService().connect(userId)`
2. Reads JWT from `SharedPreferences` → `SignalRService().loadContacts(token)`
3. `CallManager().setupCallbacks()`

### Logout Flow
1. `CallManager().clearCallbacks()`
2. `SignalRService().disconnect()`
3. `ArtefactController.clearUserData()`
4. `AuthModel.logout()`
5. Navigate to `LoginView`

### Design Notes
- SignalR connection logic is duplicated between `checkAuth` and `login`
- Reads JWT from `SharedPreferences` directly (bypasses `Token` singleton)
- Login errors are rethrown for `LoginView` to display inline
- All user-facing strings in Danish
- Commented-out code in `signup` suggests auto-login was previously considered
