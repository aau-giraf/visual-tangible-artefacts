# Admin Dashboard — Claude Code Guide

## Directory Structure

```
Frontend/admin-dashboard/src/
├── main.ts                      # Vue app bootstrap
├── App.vue                      # Root component
├── api/                         # HTTP API clients
│   ├── axios.ts                 # Configured Axios instance (base URL, JWT interceptor)
│   ├── auth.ts                  # Login/logout API calls
│   ├── admins.ts                # Admin user management
│   ├── caregivers.ts            # Caregiver management
│   ├── children.ts              # Child user management
│   ├── users.ts                 # General user operations
│   └── pairings.ts              # Caregiver-child pairing API
├── interfaces/                  # TypeScript type definitions
│   ├── Auth.ts                  # Auth request/response types
│   ├── User.ts                  # Base user interface
│   ├── Admin.ts                 # Admin user type
│   ├── Caregiver.ts             # Caregiver type
│   ├── Child.ts                 # Child type
│   ├── Artefact.ts              # Artefact type
│   ├── Category.ts              # Category type
│   └── Pairing.ts               # Pairing type
├── store/
│   └── auth.ts                  # Pinia auth store (JWT token, login state)
├── router/
│   └── index.ts                 # Vue Router (auth guards)
├── views/                       # Page-level components
│   ├── LoginView.vue            # Login page
│   ├── OverviewView.vue         # Dashboard overview
│   ├── AdminsView.vue           # Admin user management
│   ├── CaregiversView.vue       # Caregiver management
│   ├── ChildrenView.vue         # Child user management
│   ├── UsersView.vue            # All users view
│   └── PairingsView.vue         # Caregiver-child pairing management
├── layouts/
│   └── DashboardLayout.vue      # Sidebar + content layout
└── components/
    └── HelloWorld.vue           # Placeholder component
```

## Build & Run

```bash
cd Frontend/admin-dashboard
npm install                      # Install dependencies
npm run dev                      # Dev server at http://localhost:5173
npm run build                    # Production build (vue-tsc + vite)
npm run preview                  # Preview production build
```

## Tech Stack

- **Vue 3** (Composition API)
- **Vite 5** (build tool)
- **Pinia 3** (state management)
- **Vue Router 4** (routing with auth guards)
- **Axios** (HTTP client with JWT interceptor)
- **Tailwind CSS 4** (styling)
- **TypeScript 5.6**

## Key Patterns

- **Auth flow**: Login → store JWT in Pinia → Axios interceptor adds `Authorization: Bearer` header
- **API layer**: Each resource type gets its own API file using shared Axios instance
- **Type safety**: All API responses typed via `interfaces/` directory
- **Route guards**: Protected routes redirect to login if no token
- **Communicates with**: VTA.API only (no direct SyncService access)
