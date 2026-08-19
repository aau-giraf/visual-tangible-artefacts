import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Singleton, shared across tests.
    GlobalConfiguration().appConfig.clear();
  });

  tearDown(() {
    GlobalConfiguration().appConfig.clear();
  });

  group('getIceServers', () {
    test('reads configured servers from app config', () {
      GlobalConfiguration().loadFromMap({
        'IceServers': [
          {
            'urls': ['stun:turn.example.org:3478'],
          },
          {
            'urls': ['turn:turn.example.org:3478'],
            'username': 'vta',
            'credential': 'secret',
          },
        ],
      });

      final config = PlatformUtils.getIceServers();
      final servers = config['iceServers'] as List<dynamic>;

      expect(servers, hasLength(2));
      expect(config['sdpSemantics'], 'unified-plan');
      expect(servers[0]['urls'], ['stun:turn.example.org:3478']);
      expect(servers[1]['username'], 'vta');
      expect(servers[1]['credential'], 'secret');
    });

    test('omits credentials for STUN-only entries', () {
      GlobalConfiguration().loadFromMap({
        'IceServers': [
          {
            'urls': ['stun:turn.example.org:3478'],
          },
        ],
      });

      final servers =
          PlatformUtils.getIceServers()['iceServers'] as List<dynamic>;

      expect(servers[0].containsKey('username'), isFalse);
      expect(servers[0].containsKey('credential'), isFalse);
    });

    test('throws when config is missing', () {
      expect(PlatformUtils.getIceServers, throwsStateError);
    });

    test('throws when the configured list is empty', () {
      GlobalConfiguration().loadFromMap({'IceServers': <dynamic>[]});

      expect(PlatformUtils.getIceServers, throwsStateError);
    });

    test('names the fix in the error message', () {
      expect(
        PlatformUtils.getIceServers,
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('IceServers'),
        )),
      );
    });

    test('skips malformed entries instead of throwing', () {
      GlobalConfiguration().loadFromMap({
        'IceServers': [
          'not a map',
          {'username': 'no urls key'},
          {'urls': <dynamic>[]},
          {
            'urls': ['turn:good.example.org:3478'],
            'username': 'vta',
            'credential': 'secret',
          },
        ],
      });

      final servers =
          PlatformUtils.getIceServers()['iceServers'] as List<dynamic>;

      expect(servers, hasLength(1));
      expect(servers[0]['urls'], ['turn:good.example.org:3478']);
    });

    test('throws when every entry is malformed', () {
      GlobalConfiguration().loadFromMap({
        'IceServers': [
          {'urls': <dynamic>[]},
        ],
      });

      expect(PlatformUtils.getIceServers, throwsStateError);
    });
  });

  group('example config', () {
    test('has an IceServers section the parser accepts', () async {
      final contents =
          await rootBundle.loadString('assets/cfg/app_settings.example.json');
      final decoded = json.decode(contents) as Map<String, dynamic>;

      expect(decoded['IceServers'], isNotNull);

      GlobalConfiguration().loadFromMap(decoded);
      final servers =
          PlatformUtils.getIceServers()['iceServers'] as List<dynamic>;

      expect(servers, hasLength(2));
    });
  });
}
