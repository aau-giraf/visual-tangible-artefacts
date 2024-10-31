import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
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
  //await clearSharedPreferences();

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Load global configuration from assets/cfg/app_settings.json
  await GlobalConfiguration().loadFromAsset("app_settings");

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => AuthState()),
    ChangeNotifierProvider(create: (context) => ArtifactState()),
  ], child: MyApp(settingsController: settingsController)));
}
