import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/services/sync_service.dart';
import 'package:vta_app/src/singletons/user_info.dart';

/// Service that manages periodic syncing with the backend
/// Runs sync operations on a timer and provides lifecycle management
class SyncTimer {
  static final SyncTimer _instance = SyncTimer._internal();
  factory SyncTimer() => _instance;
  SyncTimer._internal();

  Timer? _timer;
  final SyncService _syncService = SyncService();
  late final UserInfo _userInfo;
  bool _isRunning = false;

  /// Start the periodic sync timer
  /// [interval] - Duration between sync attempts (default: 30 seconds)
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (_isRunning) {
      print('[SYNC-TIMER] Already running, ignoring start request');
      return;
    }

    print('[SYNC-TIMER] Starting periodic sync with interval: $interval');
    
    // Get the singleton UserInfo from GetIt
    _userInfo = GetIt.I.get<UserInfo>();
    print('[SYNC-TIMER] UserInfo singleton retrieved, current user ID: ${_userInfo.userId}');
    
    _isRunning = true;

    // Run initial sync immediately
    _performSync();

    // Set up periodic timer
    _timer = Timer.periodic(interval, (timer) {
      _performSync();
    });
  }

  /// Stop the periodic sync timer
  void stop() {
    print('[SYNC-TIMER] Stopping periodic sync');
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Perform a single sync operation
  Future<void> _performSync() async {
    print('[SYNC-TIMER] ========================================');
    print('[SYNC-TIMER] Periodic sync triggered at ${DateTime.now()}');
    
    final userId = _userInfo.userId;
    print('[SYNC-TIMER] Current user ID from singleton: $userId');
    if (userId == null) {
      print('[SYNC-TIMER] No user logged in, skipping sync');
      return;
    }

    try {
      // Use autoSync which checks if sync is needed based on threshold
      // Set threshold to 0 to force sync every time
      final success = await _syncService.autoSync(
        threshold: Duration.zero, // Always sync when called
      );
      
      if (success) {
        print('[SYNC-TIMER] Sync completed successfully');
      } else {
        print('[SYNC-TIMER] Sync failed or returned false');
      }
    } catch (e) {
      print('[SYNC-TIMER] ERROR during sync: $e');
    }
    
    print('[SYNC-TIMER] ========================================');
  }

  /// Manually trigger a sync outside the timer
  Future<void> syncNow() async {
    print('[SYNC-TIMER] Manual sync requested');
    await _performSync();
  }

  /// Check if the timer is currently running
  bool get isRunning => _isRunning;

  /// Get the current sync service instance
  SyncService get syncService => _syncService;
}
