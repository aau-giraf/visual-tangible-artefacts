import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:logging/logging.dart';


final _log = Logger('PlatformUtils');
class PlatformUtils {
  /// Base URL of VTA.API. Throws [StateError] if it is not configured.
  static String getApiUrl() => _resolveUrl(
        label: 'API',
        androidKey: 'LocalAndroid',
        iosKey: 'LocalIOS',
        defaultKey: 'Local',
        remoteKey: 'Remote',
      );

  /// Base URL of SyncService. Throws [StateError] if it is not configured.
  static String getSyncServiceUrl() => _resolveUrl(
        label: 'SyncService',
        androidKey: 'SyncServiceAndroid',
        iosKey: 'SyncServiceIOS',
        defaultKey: 'SyncService',
        remoteKey: 'SyncServiceRemote',
      );

  /// Throws rather than defaulting: a wrong-but-plausible localhost URL is how
  /// a missing config went unnoticed for months.
  static String _resolveUrl({
    required String label,
    required String androidKey,
    required String iosKey,
    required String defaultKey,
    required String remoteKey,
  }) {
    final baseUrl = _baseUrlSection(label);

    final String platform;
    final String platformKey;
    if (kIsWeb) {
      platform = 'Web';
      platformKey = defaultKey;
    } else if (Platform.isAndroid) {
      platform = 'Android';
      platformKey = androidKey;
    } else if (Platform.isIOS) {
      platform = 'iOS';
      platformKey = iosKey;
    } else {
      platform = 'Desktop';
      platformKey = defaultKey;
    }

    final url = _nonEmpty(baseUrl[platformKey]) ??
        _nonEmpty(baseUrl[defaultKey]) ??
        _nonEmpty(baseUrl[remoteKey]);

    if (url == null) {
      throw StateError(
          'No $label URL configured for $platform. Set one of '
          '"$platformKey", "$defaultKey" or "$remoteKey" under '
          'ApiSettings.BaseUrl in assets/cfg/app_settings.json. '
          '$_setupHint');
    }

    _log.info('[PlatformUtils] Using $platform $label URL: $url');
    return url;
  }

  static Map<String, dynamic> _baseUrlSection(String label) {
    final apiSettings =
        GlobalConfiguration().appConfig['ApiSettings'] as Map<String, dynamic>?;
    final baseUrl = apiSettings?['BaseUrl'] as Map<String, dynamic>?;

    if (baseUrl == null) {
      throw StateError(
          'Cannot resolve the $label URL: ApiSettings.BaseUrl is missing from '
          'assets/cfg/app_settings.json. $_setupHint');
    }

    return baseUrl;
  }

  static String? _nonEmpty(dynamic value) =>
      (value is String && value.isNotEmpty) ? value : null;

  static const String _setupHint =
      'Copy assets/cfg/app_settings.example.json to '
      'assets/cfg/app_settings.json to create it.';
}
