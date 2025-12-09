# Sync Service with SQLite Database Integration

## Overview

The `SyncService` integrates backend API calls with local SQLite database storage, providing:
- **Server-side filtering** for efficient network usage
- **Local database caching** for offline access
- **Automatic sync tracking** with metadata persistence
- **Hybrid queries** (local-only or API with caching)

## Architecture

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐
│  Frontend   │─────▶│ Sync Service │─────▶│  Backend    │
│     App     │◀─────│              │◀─────│     API     │
└─────────────┘      └──────┬───────┘      └─────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │   SQLite DB  │
                     │  (Caching)   │
                     └──────────────┘
```

## Key Methods

### `checkForChanges(DateTime since)`
Fetches changes from the API and updates local database.
```dart
final response = await syncService.checkForChanges(yesterday);
// - Calls backend API
// - Updates local SQLite database
// - Returns FileChangeRecord list
```

### `checkLocalChanges(DateTime since)`
Queries only the local database (no network call).
```dart
final response = await syncService.checkLocalChanges(yesterday);
// - Queries local SQLite database only
// - Works offline
// - Fast response
```

### `syncFromServer({DateTime? since})`
Full sync operation that downloads and caches data.
```dart
final success = await syncService.syncFromServer();
// - Fetches changes from server
// - Updates local database
// - Updates sync metadata
```

### `autoSync({Duration threshold})`
Automatic sync with threshold checking.
```dart
final success = await syncService.autoSync(
  threshold: const Duration(hours: 1),
);
// - Checks if sync needed
// - Performs sync if threshold exceeded
// - Returns true if data is current
```

### `getLastSyncDate()`
Get when the last successful sync occurred.
```dart
final lastSync = await syncService.getLastSyncDate();
if (lastSync == null) {
  print('Never synced');
} else {
  print('Last sync: $lastSync');
}
```

### `needsSync({Duration threshold})`
Check if sync is needed based on time threshold.
```dart
if (await syncService.needsSync(threshold: Duration(hours: 2))) {
  await syncService.syncFromServer();
}
```

## Database Tables

### artefact
Stores artefact data locally:
- `artefact_id` (PRIMARY KEY)
- `artefact_index`, `user_id`, `category_id`
- `image_path`, `sound_path`
- `modified_date` (Unix timestamp)
- `name`, `name_shown`
- `is_deleted` (soft delete flag)

### saved_board
Stores board data locally:
- `id` (PRIMARY KEY)
- `name`, `user_id`
- `created_date`, `modified_date`
- `saved_artefact_ids`, `artefact_ids`
- `is_deleted` (soft delete flag)

### sync_metadata
Tracks sync operations:
- `id` (PRIMARY KEY)
- `user_id`, `entity_type` (artefact/board)
- `last_sync_date` (when last synced)
- `last_check_date` (when last checked)

## Usage Patterns

### Pattern 1: Initial Load
```dart
// First time loading app
final syncService = SyncService();

// Check if we have local data
final counts = await syncService.getLocalItemCounts();

if (counts['artefacts']! == 0) {
  // No local data, do full sync
  await syncService.syncFromServer(
    since: DateTime.now().subtract(Duration(days: 365)),
  );
} else {
  // Have local data, just sync recent changes
  await syncService.autoSync();
}

// Now query local database for fast loading
final local = await syncService.checkLocalChanges(DateTime(2020, 1, 1));
```

### Pattern 2: Periodic Background Sync
```dart
// Check every time app resumes
Timer.periodic(Duration(minutes: 15), (timer) async {
  if (await syncService.needsSync(threshold: Duration(minutes: 15))) {
    await syncService.syncFromServer();
  }
});
```

### Pattern 3: Offline-First with Background Sync
```dart
// Always use local data for UI
final localData = await syncService.checkLocalChanges(DateTime(2020, 1, 1));

// Display local data immediately
updateUI(localData);

// Sync in background
syncService.autoSync().then((success) {
  if (success) {
    // Refresh UI with updated data
    syncService.checkLocalChanges(DateTime(2020, 1, 1))
        .then(updateUI);
  }
});
```

### Pattern 4: Smart Sync
```dart
// Only sync if needed and on WiFi
Future<void> smartSync() async {
  final connectivity = await Connectivity().checkConnectivity();
  
  if (connectivity == ConnectivityResult.wifi) {
    if (await syncService.needsSync(threshold: Duration(hours: 1))) {
      await syncService.syncFromServer();
    }
  } else {
    // On mobile data, just check local
    final local = await syncService.checkLocalChanges(DateTime(2020, 1, 1));
  }
}
```

## Benefits

### ✅ Offline Support
- Query local database when offline
- App works without internet connection
- Data persists between app sessions

### ✅ Performance
- Fast queries from local SQLite
- No network latency for local queries
- Reduced API calls with caching

### ✅ Data Consistency
- Automatic sync tracking
- Timestamp-based change detection
- Soft delete support

### ✅ Battery Efficiency
- Fewer network calls
- Smart sync thresholds
- Background sync scheduling

## Configuration

### Sync Thresholds
```dart
// Aggressive sync (every 5 minutes)
await syncService.autoSync(threshold: Duration(minutes: 5));

// Conservative sync (every 6 hours)
await syncService.autoSync(threshold: Duration(hours: 6));

// Manual control
if (await syncService.needsSync(threshold: Duration(days: 1))) {
  // User-triggered sync
  await syncService.syncFromServer();
}
```

## Error Handling

```dart
try {
  final response = await syncService.checkForChanges(since);
  
  if (response == null) {
    // Network error or API failure
    // Fall back to local database
    final local = await syncService.checkLocalChanges(since);
    return local;
  }
  
  return response;
} catch (e) {
  // Handle error
  print('Sync error: $e');
  
  // Always can fall back to local
  return await syncService.checkLocalChanges(since);
}
```

## Best Practices

1. **Always provide offline fallback**: Use `checkLocalChanges()` when network fails
2. **Use auto-sync**: Let the service decide when to sync with `autoSync()`
3. **Set reasonable thresholds**: Balance freshness vs. battery/network usage
4. **Query local first**: For fast UI, show local data then refresh
5. **Handle errors gracefully**: Always fall back to local database
6. **Track sync status**: Check `getLastSyncDate()` to inform users

## Performance Tips

- **Batch updates**: Sync in background, not on every user action
- **Use thresholds**: Don't sync more often than needed
- **Local queries are fast**: Use them for UI rendering
- **Index important fields**: Database has indexes on `user_id`, `modified_date`
- **Soft deletes**: Never hard delete to maintain sync consistency

## Troubleshooting

### No data in local database
```dart
final counts = await syncService.getLocalItemCounts();
if (counts['artefacts']! == 0) {
  // Force full sync
  await syncService.syncFromServer(
    since: DateTime.now().subtract(Duration(days: 365)),
  );
}
```

### Sync seems stuck
```dart
// Check last sync date
final lastSync = await syncService.getLastSyncDate();
print('Last sync: $lastSync');

// Force new sync
await syncService.setLastSyncDate(DateTime.now().subtract(Duration(days: 1)));
await syncService.syncFromServer();
```

### Local data out of sync
```dart
// Clear local data and re-sync
final dbHelper = DatabaseHelper.instance;
await dbHelper.deleteDatabase();

// Re-sync everything
await syncService.syncFromServer(
  since: DateTime(2020, 1, 1),
);
```
