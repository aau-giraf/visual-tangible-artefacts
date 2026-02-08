// ignore_for_file: avoid_print

import 'package:vta_app/src/services/sync_service.dart';

/// Example usage of the SyncService
/// 
/// This demonstrates how to use the sync checker to get a list of files
/// that have been changed since a specific date.
/// 
/// NOTE: All filtering is done on the backend - the frontend just sends
/// a date parameter and receives already-filtered results.
///
/// Prerequisites: register [ApiProvider], [Token] and [UserInfo] in GetIt
/// before constructing [SyncService].
class SyncServiceExample {
  final SyncService _syncService;

  SyncServiceExample()
      : _syncService = SyncService();

  /// Example 1: Check for all changes since a specific date
  Future<void> checkAllChanges() async {
    // Check for changes since 24 hours ago
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    
    final response = await _syncService.checkForChanges(yesterday);
    
    if (response != null) {
      print('Found ${response.totalChanges} changes since $yesterday');
      
      for (final change in response.changedFiles) {
        print('${change.fileType}: ${change.fileName} (${change.fileId})');
        print('  Modified: ${change.modifiedDate}');
        if (change.imageUrl != null) {
          print('  Image: ${change.imageUrl}');
        }
        if (change.soundUrl != null) {
          print('  Sound: ${change.soundUrl}');
        }
      }
    } else {
      print('Failed to check for changes');
    }
  }

  /// Example 2: Check for changes grouped by type
  Future<void> checkChangesGrouped() async {
    final lastWeek = DateTime.now().subtract(const Duration(days: 7));
    
    final grouped = await _syncService.checkForChangesGrouped(lastWeek);
    
    if (grouped != null) {
      print('Artefact changes: ${grouped['artefact']?.length ?? 0}');
      for (final artefact in grouped['artefact'] ?? []) {
        print('  - ${artefact.fileName} (modified: ${artefact.modifiedDate})');
      }
      
      print('Board changes: ${grouped['board']?.length ?? 0}');
      for (final board in grouped['board'] ?? []) {
        print('  - ${board.fileName} (modified: ${board.modifiedDate})');
      }
    }
  }

  /// Example 3: Get a simple summary of changes
  Future<void> checkSummary() async {
    final lastMonth = DateTime.now().subtract(const Duration(days: 30));
    
    final summary = await _syncService.getChangeSummary(lastMonth);
    
    if (summary != null) {
      print('Changes in the last 30 days:');
      print('  Total: ${summary['total']}');
      print('  Artefacts: ${summary['artefacts']}');
      print('  Boards: ${summary['boards']}');
    }
  }

  /// Example 4: Check if there are any changes
  Future<void> hasAnyChanges() async {
    final lastSync = DateTime(2024, 11, 1); // Example: last sync date
    
    final hasChanges = await _syncService.hasChanges(lastSync);
    
    if (hasChanges) {
      print('There are new changes to sync!');
      // Trigger sync process...
    } else {
      print('No changes detected, everything is up to date.');
    }
  }

  /// Example 5: Periodic sync check with automatic synchronization
  Future<void> performPeriodicSync({
    required DateTime lastSyncDate,
    required Function(List<FileChangeRecord>) onChangesDetected,
  }) async {
    print('Checking for changes since: $lastSyncDate');
    
    final response = await _syncService.checkForChanges(lastSyncDate);
    
    if (response != null && response.totalChanges > 0) {
      print('Found ${response.totalChanges} file(s) to sync');
      
      // Notify the caller about changes
      onChangesDetected(response.changedFiles);
      
      // Return the latest modification date for next sync
      final latestChange = response.changedFiles.first.modifiedDate;
      print('Latest change: $latestChange');
    } else {
      print('No changes detected');
    }
  }

  /// Example 6: Sync only specific file types
  Future<void> syncOnlyArtefacts() async {
    final since = DateTime.now().subtract(const Duration(hours: 6));
    
    final grouped = await _syncService.checkForChangesGrouped(since);
    
    if (grouped != null) {
      final artefactChanges = grouped['artefact'] ?? [];
      
      if (artefactChanges.isNotEmpty) {
        print('Syncing ${artefactChanges.length} artefact(s)...');
        
        for (final artefact in artefactChanges) {
          print('Downloading artefact: ${artefact.fileName}');
          // Download image from artefact.imageUrl
          // Download sound from artefact.soundUrl
        }
      }
    }
  }

  /// Example 7: Get changes and filter by specific criteria
  Future<void> getRecentImageChanges() async {
    final since = DateTime.now().subtract(const Duration(days: 3));
    
    final response = await _syncService.checkForChanges(since);
    
    if (response != null) {
      // Filter only changes that have images
      final withImages = response.changedFiles
          .where((change) => change.imageUrl != null)
          .toList();
      
      print('Found ${withImages.length} files with image changes');
      
      for (final file in withImages) {
        print('${file.fileName}: ${file.imageUrl}');
      }
    }
  }
}

/// Usage example in a widget or service
/// Assumes GetIt singletons (ApiProvider, Token, UserInfo) are registered.
void demonstrateUsage() async {
  final example = SyncServiceExample();

  // Run various examples
  await example.checkAllChanges();
  await example.checkChangesGrouped();
  await example.checkSummary();
  await example.hasAnyChanges();
  
  // Example of periodic sync with callback
  await example.performPeriodicSync(
    lastSyncDate: DateTime.now().subtract(const Duration(days: 1)),
    onChangesDetected: (changes) {
      print('Processing ${changes.length} changes...');
      // Implement your sync logic here
    },
  );
}
