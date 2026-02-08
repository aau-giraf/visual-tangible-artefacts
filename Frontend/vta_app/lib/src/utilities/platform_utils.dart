import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:logging/logging.dart';


final _log = Logger('PlatformUtils');
class PlatformUtils {
  static String getApiUrl() {
    String? url;
    try {
      final appConfig = GlobalConfiguration().appConfig;
      final apiSettings = appConfig['ApiSettings'] as Map<String, dynamic>?;
      final baseUrl = apiSettings?['BaseUrl'] as Map<String, dynamic>?;

      if (kIsWeb) {
        url = baseUrl?['Local'] as String? ?? baseUrl?['Remote'] as String?;
      } else if (Platform.isAndroid) {
        url = baseUrl?['LocalAndroid'] as String? ??
            baseUrl?['Local'] as String? ??
            baseUrl?['Remote'] as String?;
      } else if (Platform.isIOS) {
        url = baseUrl?['LocalIOS'] as String? ??
            baseUrl?['Local'] as String? ??
            baseUrl?['Remote'] as String?;
      } else {
        url = baseUrl?['Local'] as String? ?? baseUrl?['Remote'] as String?;
      }
    } catch (e) {
      _log.fine('[PlatformUtils] Error reading config: $e');
    }

    // Apply fallbacks if url is still null
    if (url == null) {
      if (kIsWeb) {
        url = 'http://localhost:5000/api/'; // Fallback for web
      } else if (Platform.isAndroid) {
        url = 'http://10.0.2.2:5000/api/'; // Android emulator default
      } else if (Platform.isIOS) {
        url = 'http://localhost:5000/api/'; // iOS simulator default
      } else {
        url = 'http://localhost:5000/api/'; // Desktop fallback
      }
    }

    _log.info(
        '[PlatformUtils] Using ${kIsWeb ? 'Web' : Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Desktop'} API URL: $url');
    return url;
  }

  static String getSyncServiceUrl() {
    String? url;
    try {
      final appConfig = GlobalConfiguration().appConfig;
      final apiSettings = appConfig['ApiSettings'] as Map<String, dynamic>?;
      final baseUrl = apiSettings?['BaseUrl'] as Map<String, dynamic>?;

      if (kIsWeb) {
        url = baseUrl?['SyncService'] as String? ??
            baseUrl?['SyncServiceRemote'] as String?;
      } else if (Platform.isAndroid) {
        url = baseUrl?['SyncServiceAndroid'] as String? ??
            baseUrl?['SyncService'] as String? ??
            baseUrl?['SyncServiceRemote'] as String?;
      } else if (Platform.isIOS) {
        url = baseUrl?['SyncServiceIOS'] as String? ??
            baseUrl?['SyncService'] as String? ??
            baseUrl?['SyncServiceRemote'] as String?;
      } else {
        url = baseUrl?['SyncService'] as String? ??
            baseUrl?['SyncServiceRemote'] as String?;
      }
    } catch (e) {
      _log.fine('[PlatformUtils] Error reading config: $e');
    }

    // Apply fallbacks if url is still null
    if (url == null) {
      if (kIsWeb) {
        url = 'http://localhost:5001/'; // Fallback for web
      } else if (Platform.isAndroid) {
        url = 'http://10.0.2.2:5001/'; // Android emulator default
      } else if (Platform.isIOS) {
        url = 'http://localhost:5001/'; // iOS simulator default
      } else {
        url = 'http://localhost:5001/'; // Desktop fallback
      }
    }

    _log.info(
        '[PlatformUtils] Using ${kIsWeb ? 'Web' : Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Desktop'} SyncService URL: $url');
    return url;
  }
}
