# AuthModel

**File:** `Frontend/vta_app/lib/src/models/auth_model.dart` (191 lines)

## Purpose

Handles authentication lifecycle: login, signup, token caching, logout, and user retrieval. Manages JWT token persistence via `SharedPreferences`.

## Class: `AuthModel`

### Dependencies
- `ApiProvider` — HTTP client (injected)
- `Token` singleton — holds current JWT in memory
- `UserInfo` singleton — holds current userId in memory
- `SharedPreferences` — persistent storage for token and userId

### Key Methods

| Method | Description |
|--------|-------------|
| `checkAuth()` | Returns `true` if a JWT token exists in SharedPreferences |
| `loadCache()` | Restores token and userId from SharedPreferences into singletons |
| `login(username, password)` | POST `Users/Login`, stores token+userId in singletons and cache |
| `signup(SignupForm)` | POST `Users/Signup`, same token handling as login |
| `logout()` | Clears all SharedPreferences **except** profile picture data, then clears singletons |
| `getUser(userId)` | GET `Users/{id}` with Bearer token, returns `User?` |
| `cacheData(token, userId)` | Writes token/userId to SharedPreferences |
| `clearCacheData()` | Removes token/userId from SharedPreferences and clears singletons |

### Error Handling
- `_throwAuthException(statusCode)` maps HTTP status codes to Danish error messages
- Network errors (SocketException, DNS failures) caught and wrapped with connectivity message
- Throws `AuthException` for all error cases

## Class: `AuthException`
Custom exception with optional `message` field (default: `'AuthException'`).

## Design Notes
- Profile picture data is explicitly preserved across logout/clear operations.
- Error messages are in Danish (e.g., "Forkert brugernavn eller kodeord").
- Login and signup both return `LoginResponse` (containing `token` and `userId`).
