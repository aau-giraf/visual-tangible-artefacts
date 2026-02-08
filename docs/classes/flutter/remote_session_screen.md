# RemoteSessionScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/remote_session_screen.dart`

## Overview
The `RemoteSessionScreen` serves as the "Contacts" or "Lobby" screen for initiating remote sessions. It lists available users (e.g., children a caregiver works with) and displays their availability status.

## Responsibilities
- **Contact Loading:** Fetches the list of associated contacts/children for the logged-in user using `UserRepository`.
- **Online Status:** Subscribes to `SignalRService` online status updates to show real-time availability (online/offline indicators) for each contact.
- **Navigation:** Provides entry points to initiate a session or call with a selected contact.
- **Refresh Logic:** Periodically or event-based refreshing of contact status.

## Key Methods
- `_loadContacts()`: Fetches user data from the backend.
- `_listenForOnlineStatusChanges()`: Sets up the callback for `onUserOnlineStatusChanged` from SignalR to trigger UI updates.

## Dependencies
- `UserRepository`: Data access layer for fetching user relations.
- `SignalRService`: Monitors real-time user presence.
- `SharedPreferences`: Used to retrieve the authentication token for API requests.
