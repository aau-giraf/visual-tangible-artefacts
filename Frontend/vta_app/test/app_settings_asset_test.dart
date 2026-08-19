import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails if `assets/cfg/` is dropped from pubspec.yaml again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('app_settings example config', () {
    test('is bundled as an asset', () async {
      final contents =
          await rootBundle.loadString('assets/cfg/app_settings.example.json');

      expect(contents, isNotEmpty);
    });

    test('is valid JSON with the keys the app reads', () async {
      final contents =
          await rootBundle.loadString('assets/cfg/app_settings.example.json');
      final config = json.decode(contents) as Map<String, dynamic>;

      final apiSettings = config['ApiSettings'] as Map<String, dynamic>?;
      expect(apiSettings, isNotNull,
          reason: 'DataRepository reads appConfig["ApiSettings"]');

      final baseUrl = apiSettings!['BaseUrl'] as Map<String, dynamic>?;
      expect(baseUrl, isNotNull,
          reason: 'PlatformUtils reads ApiSettings.BaseUrl');

      for (final key in const [
        'Local',
        'LocalAndroid',
        'LocalIOS',
        'Remote',
        'SyncService',
        'SyncServiceAndroid',
        'SyncServiceIOS',
        'SyncServiceRemote',
      ]) {
        expect(baseUrl!.containsKey(key), isTrue,
            reason: 'PlatformUtils looks up BaseUrl["$key"]');
      }

      expect(config['OpenAi'], isNotNull,
          reason: 'addPicture.dart reads appConfig["OpenAi"]["ApiKey"]');
    });

    test('carries no secrets', () async {
      final contents =
          await rootBundle.loadString('assets/cfg/app_settings.example.json');
      final config = json.decode(contents) as Map<String, dynamic>;
      final openAi = config['OpenAi'] as Map<String, dynamic>;

      expect(openAi['ApiKey'], isEmpty,
          reason: 'the committed example must never hold a real key');
    });
  });
}
