import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'package:global_configuration/global_configuration.dart';

Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clear SharedPreferences, for testing
  // await clearSharedPreferences();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Initialize the CameraManager
  if (Platform.isAndroid || Platform.isIOS) {
    CameraManager().initialize();
  }
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Load global configuration from assets/cfg/app_settings.json
  await GlobalConfiguration().loadFromAsset("app_settings");

  await Settings.init(cacheProvider: SharePreferenceCache());
  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AuthState()),
    ChangeNotifierProvider(create: (context) => ArtifactState()),
    ChangeNotifierProvider(create: (context) => UserState()),
  ], child: MyApp(settingsController: settingsController)));
}
