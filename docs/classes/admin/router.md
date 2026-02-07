# Admin Dashboard Router Documentation

**File:** `Frontend/admin-dashboard/src/router/index.ts`

## Overview
This file defines the routing configuration for the Admin Dashboard using `vue-router`. It maps URLs to Vue components and handles navigation guards for authentication.

## Routes
- `/login`: Maps to `LoginView`.
- `/dashboard`: The main authenticated area, using `DashboardLayout`.
    - `/dashboard/overview`: `OverviewView` (Default redirect).
    - `/dashboard/users`: `UsersView`.
    - `/dashboard/children`: `ChildrenView`.
    - `/dashboard/caregivers`: `CaregiversView`.
    - `/dashboard/pairings`: `PairingsView`.
    - `/dashboard/admins`: `AdminsView`.
- `/*`: Wildcard redirect to `/login`.

## Guards
- **Global `beforeEach`**: Checks `to.meta.requiresAuth`. If true and the user is not authenticated (via `authStore.isAuthenticated`), redirects to `/login`.
