# Admin Dashboard Summary

**Path:** `Frontend/admin-dashboard/`

## Core Infrastructure

### Entry Point (`src/main.ts`)
- Initializes the Vue 3 application.
- Uses `createPinia()` for state management.
- Uses `router` for navigation.
- Mounts to `#app`.

### Root Component (`src/App.vue`)
- Simple container rendering `<router-view />`.

### Layout (`src/layouts/DashboardLayout.vue`)
- **Role:** Provides the common structure for authenticated pages (Sidebar, Header, Content Area).
- *Note: Inferred from usage in router, file not explicitly read but standard pattern.*

## Simple Views

### Login View (`src/views/LoginView.vue`)
- **Features:**
    - Username/Password form.
    - "Remember Me" checkbox.
    - Error handling (displays alert on invalid credentials).
    - Loading state for the submit button.
- **Logic:** Calls `authStore.login()` on submit.

### Other Management Views (Inferred)
- **UsersView:** General user management.
- **ChildrenView:** Management specific to Child accounts.
- **CaregiversView:** Management specific to Caregiver accounts.
- **AdminsView:** Management of other admin accounts.
*These views likely follow a similar pattern to `PairingsView` (Table list + Create/Edit actions).*

## API Layer (`src/api/`)
- Contains services for making HTTP requests to the backend (e.g., `auth.ts`, `caregivers.ts`, `children.ts`, `pairings.ts`).

## Types (`src/interfaces/`)
- TypeScript interfaces defining the shape of API Data Transfer Objects (DTOs) like `UserGetDTO`, `UserLoginDTO`, etc.
