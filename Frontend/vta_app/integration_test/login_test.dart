import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:vta_app/main.dart' as app;

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  const dartDefineUser = String.fromEnvironment('GIRAF_USERNAME');
  const dartDefinePass = String.fromEnvironment('GIRAF_PASSWORD');
  final String username = dartDefineUser.isNotEmpty
      ? dartDefineUser
      : (dotenv.env['GIRAF_USERNAME'] ?? '');
  final String password = dartDefinePass.isNotEmpty
      ? dartDefinePass
      : (dotenv.env['GIRAF_PASSWORD'] ?? '');

  assert(username.isNotEmpty,
      'GIRAF_USERNAME must be provided via --dart-define or .env');
  assert(password.isNotEmpty,
      'GIRAF_PASSWORD must be provided via --dart-define or .env');

  patrolTest(
    'login validation errors show and correct credentials log in',
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      app.main();
      await $.pumpAndSettle();

      await $('Log in').waitUntilVisible(timeout: const Duration(seconds: 20));

      await $('Fortsæt').tap();
      await $('Indtast venligst dit brugernavn').waitUntilVisible();
      await $('Indtast venligst dit kodeord').waitUntilVisible();

      final usernameField = $(TextFormField).at(0);
      final passwordField = $(TextFormField).at(1);

      await usernameField.waitUntilVisible();
      await usernameField.tap();
      await usernameField.enterText('wrong');

      await passwordField.tap();
      await passwordField.enterText('wrong');
      await $('Fortsæt').tap();
      await $('Invalid username or password')
          .waitUntilVisible(timeout: const Duration(seconds: 20));

      await usernameField.tap();
      await usernameField.enterText(username);

      await passwordField.tap();
      await passwordField.enterText(password);
      await $('Fortsæt').tap();

      await $(Icons.supervised_user_circle_outlined)
          .waitUntilVisible(timeout: const Duration(seconds: 30));
      expect($('Log in').exists, isFalse);
    },
  );
}
