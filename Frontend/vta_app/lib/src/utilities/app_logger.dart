import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Centralised logging configuration for the VTA app.
///
/// Call [AppLogger.init] once in `main()` before `runApp()`.
/// Then create per-file loggers with:
/// ```dart
/// final _log = Logger('MyClassName');
/// _log.info('...');
/// ```
class AppLogger {
  AppLogger._();

  /// Initialise the root logger.
  ///
  /// In debug mode every message is forwarded to `developer.log`
  /// (visible in DevTools / `flutter logs`).
  /// In release mode only warnings and above are printed.
  static void init() {
    hierarchicalLoggingEnabled = true;
    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      developer.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }
}
