import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/services/sync_service.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:logging/logging.dart';


final _log = Logger('SyncTimer');
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
  int _syncCount = 0;

  /// Start the periodic sync timer
  /// [interval] - Duration between sync attempts (default: 30 seconds)
  void start({Duration interval = const Duration(seconds: 30)}) {
    if (_isRunning) {
      stop();
    }
    
    try {
      // Get the singleton UserInfo from GetIt
      _userInfo = GetIt.I.get<UserInfo>();
      _log.info('[SYNC-TIMER] Starting periodic sync (${interval.inSeconds}s interval)');
    } catch (e) {
      _log.info('[SYNC-TIMER] ERROR: Failed to get UserInfo: $e');
      return;
    }
    
    _isRunning = true;
    _syncCount = 0;

    // Run initial sync immediately
    _performSync();

    // Set up periodic timer
    try {
      _timer = Timer.periodic(interval, (timer) {
        _performSync();
      });
    } catch (e) {
      _log.info('[SYNC-TIMER] ERROR creating timer: $e');
      _isRunning = false;
    }
  }

  /// Stop the periodic sync timer
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Perform a single sync operation
  Future<void> _performSync() async {
    _syncCount++;
    
    final userId = _userInfo.userId;
    if (userId == null || userId.isEmpty) return;

    try {
      // Use autoSync which checks if sync is needed based on threshold
      // Set threshold to 0 to force sync every time
      final success = await _syncService.autoSync(
        threshold: Duration.zero, // Always sync when called
      );
      
      if (!success) {
        _log.info('[SYNC-TIMER] Sync failed');
      }
    } catch (e) {
      _log.info('[SYNC-TIMER] ERROR during sync: $e');
    }
  }

  /// Manually trigger a sync outside the timer
  Future<void> syncNow() async {
    await _performSync();
  }

  /// Check if the timer is currently running
  bool get isRunning => _isRunning;

  /// Get the current sync service instance
  SyncService get syncService => _syncService;
  
  /// Get current status for debugging
  String getStatus() {
    return '''
[SYNC-TIMER] Status Report:
  - isRunning: $_isRunning
  - timer exists: ${_timer != null}
  - timer is active: ${_timer?.isActive ?? false}
  - sync count: $_syncCount
  - user ID: ${_userInfo.userId ?? "not initialized"}
''';
  }
  
  /// Print current status
  void printStatus() {
    _log.info(getStatus());
  }
}
