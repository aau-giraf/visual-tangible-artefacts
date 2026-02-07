# Auth Store Documentation

**File:** `Frontend/admin-dashboard/src/store/auth.ts`

## Overview
A Pinia store managing the authentication state for the admin dashboard.

## State
- `token` (Ref<string>): The JWT token.
- `user` (Ref<object>): The current user object.
- `isAuthenticated` (Ref<boolean>): Derived from the presence of a token.

## Actions
- `login(credentials)`:
    - **Development Mode:** Has a block for mocked local login (commented out in production).
    - **Production Mode:** Calls `apiLogin`, stores the returned token and user ID in local storage and state, updates `isAuthenticated`, and redirects to `/dashboard`.
- `logout()`: Clears state and local storage, redirects to `/login`.

## Persistence
- Initializes state from `localStorage` (`token`, `user`) to persist sessions across refreshes.
