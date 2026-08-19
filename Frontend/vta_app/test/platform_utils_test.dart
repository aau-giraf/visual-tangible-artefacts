import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';

/// The URL lookups must throw when unconfigured rather than return a localhost
/// default. Silent defaults are why a missing config went unnoticed for months.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GlobalConfiguration().appConfig.clear());
  tearDown(() => GlobalConfiguration().appConfig.clear());

  group('getApiUrl', () {
    test('throws when no config is loaded', () {
      expect(PlatformUtils.getApiUrl, throwsStateError);
    });

    test('throws when ApiSettings.BaseUrl is missing', () {
      GlobalConfiguration().loadFromMap({'ApiSettings': <String, dynamic>{}});

      expect(PlatformUtils.getApiUrl, throwsStateError);
    });

    test('throws when every candidate key is empty', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {'Local': '', 'Remote': ''},
        },
      });

      expect(PlatformUtils.getApiUrl, throwsStateError);
    });

    test('names the fix in the error message', () {
      expect(
        PlatformUtils.getApiUrl,
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('app_settings.example.json'),
        )),
      );
    });

    test('returns the configured URL', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {'Local': 'http://localhost:5192/api/'},
        },
      });

      expect(PlatformUtils.getApiUrl(), 'http://localhost:5192/api/');
    });

    test('falls back to Remote when Local is empty', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {'Local': '', 'Remote': 'https://vta.example.org/api/'},
        },
      });

      expect(PlatformUtils.getApiUrl(), 'https://vta.example.org/api/');
    });
  });

  group('getSyncServiceUrl', () {
    test('throws when unconfigured', () {
      expect(PlatformUtils.getSyncServiceUrl, throwsStateError);
    });

    test('returns the configured URL', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {'SyncService': 'http://localhost:5002/'},
        },
      });

      expect(PlatformUtils.getSyncServiceUrl(), 'http://localhost:5002/');
    });

    test('is independent of the API URL keys', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {'Local': 'http://localhost:5192/api/'},
        },
      });

      expect(PlatformUtils.getSyncServiceUrl, throwsStateError);
    });
  });

  group('example config', () {
    test('satisfies both lookups', () {
      GlobalConfiguration().loadFromMap({
        'ApiSettings': {
          'BaseUrl': {
            'Local': 'http://localhost:5192/api/',
            'SyncService': 'http://localhost:5002/',
          },
        },
      });

      expect(PlatformUtils.getApiUrl(), isNotEmpty);
      expect(PlatformUtils.getSyncServiceUrl(), isNotEmpty);
    });
  });
}
