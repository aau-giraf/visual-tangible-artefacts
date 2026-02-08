import 'dart:async';
import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/services/sync_service.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:logging/logging.dart';


final _log = Logger('SyncTimer');

/// Default interval between sync attempts.
const _defaultInterval = Duration(seconds: 30);

/// Maximum interval after consecutive failures (5 minutes).
const _maxInterval = Duration(minutes: 5);

/// Service that manages periodic syncing with the backend.
///
/// On consecutive failures the timer interval grows exponentially
/// (30 s → 60 s → 120 s → … up to 5 min). A successful sync resets the
/// interval to the default.
class SyncTimer {
  static final SyncTimer _instance = SyncTimer._internal();
  factory SyncTimer() => _instance;
  SyncTimer._internal();

  Timer? _timer;
  final SyncService _syncService = SyncService();
  late final UserInfo _userInfo;
  bool _isRunning = false;
  int _syncCount = 0;

  /// Number of consecutive failed sync cycles.
  int _consecutiveFailures = 0;

  /// The current (possibly backed-off) interval.
  Duration _currentInterval = _defaultInterval;

  /// The base interval configured at [start].
  Duration _baseInterval = _defaultInterval;

  /// Start the periodic sync timer.
  ///
  /// [interval] — Duration between sync attempts when everything is healthy.
  void start({Duration interval = _defaultInterval}) {
    if (_isRunning) {
      stop();
    }
    
    try {
      _userInfo = GetIt.I.get<UserInfo>();
      _log.info('[SYNC-TIMER] Starting periodic sync (${interval.inSeconds}s interval)');
    } catch (e) {
      _log.warning('[SYNC-TIMER] Failed to get UserInfo: $e');
      return;
    }
    
    _isRunning = true;
    _syncCount = 0;
    _consecutiveFailures = 0;
    _baseInterval = interval;
    _currentInterval = interval;

    // Run initial sync immediately
    _performSync();

    // Set up periodic timer
    _scheduleNext();
  }

  /// Stop the periodic sync timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  /// Schedule the next sync tick using [_currentInterval].
  void _scheduleNext() {
    _timer?.cancel();
    if (!_isRunning) return;

    _timer = Timer(_currentInterval, () {
      _performSync();
      _scheduleNext();
    });
  }

  /// Perform a single sync operation and adjust backoff on failure.
  Future<void> _performSync() async {
    _syncCount++;
    
    final userId = _userInfo.userId;
    if (userId == null || userId.isEmpty) return;

    try {
      final result = await _syncService.autoSync(
        threshold: Duration.zero,
      );
      
      if (result.success) {
        if (_consecutiveFailures > 0) {
          _log.info(
            '[SYNC-TIMER] Sync recovered after $_consecutiveFailures failures. '
            'Resetting interval to ${_baseInterval.inSeconds}s.',
          );
        }
        _consecutiveFailures = 0;
        _currentInterval = _baseInterval;
      } else {
        _onFailure();
      }
    } catch (e) {
      _log.warning('[SYNC-TIMER] ERROR during sync: $e');
      _onFailure();
    }
  }

  /// Increase backoff after a failure.
  void _onFailure() {
    _consecutiveFailures++;
    _currentInterval = Duration(
      milliseconds: min(
        (_baseInterval.inMilliseconds * pow(2, _consecutiveFailures)).toInt(),
        _maxInterval.inMilliseconds,
      ),
    );
    _log.info(
      '[SYNC-TIMER] Sync failed ($_consecutiveFailures in a row). '
      'Next attempt in ${_currentInterval.inSeconds}s.',
    );
    // Reschedule with new interval
    _scheduleNext();
  }

  /// Manually trigger a sync outside the timer.
  Future<void> syncNow() async {
    await _performSync();
  }

  /// Check if the timer is currently running.
  bool get isRunning => _isRunning;

  /// Get the current sync service instance.
  SyncService get syncService => _syncService;

  /// Number of consecutive failures.
  int get consecutiveFailures => _consecutiveFailures;

  /// Current (possibly backed-off) interval.
  Duration get currentInterval => _currentInterval;
  
  /// Get current status for debugging.
  String getStatus() {
    return '''
[SYNC-TIMER] Status Report:
  - isRunning: $_isRunning
  - timer exists: ${_timer != null}
  - timer is active: ${_timer?.isActive ?? false}
  - sync count: $_syncCount
  - consecutive failures: $_consecutiveFailures
  - current interval: ${_currentInterval.inSeconds}s
  - user ID: ${_userInfo.userId ?? "not initialized"}
''';
  }
  
  /// Print current status.
  void printStatus() {
    _log.info(getStatus());
  }
}
