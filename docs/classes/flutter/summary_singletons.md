# Singletons Summary

**Path:** `Frontend/vta_app/lib/src/singletons/`

## Files

| File | Lines | Description |
|------|-------|-------------|
| `token.dart` | 4 | `Token` class with `String? value` — holds the JWT token in memory. Injected into `AuthModel`. |
| `user_info.dart` | 4 | `UserInfo` class with `String? userId` — holds the current user ID in memory. Injected into `AuthModel`. |

These are simple value holders, not actual singletons (no static instance). They're instantiated in `main.dart` and passed around via dependency injection.
