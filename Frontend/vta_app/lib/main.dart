import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/controllers/board_controller.dart';
import 'package:vta_app/src/models/board_model.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:get_it/get_it.dart';

Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Clear SharedPreferences, for testing
  await clearSharedPreferences();

  // Load global configuration from assets/cfg/app_settings.json
  await GlobalConfiguration().loadFromAsset("app_settings");

  // Set up global token with GetIt
  GetIt.I.registerSingleton<Token>(Token());
  var token = GetIt.I.get<Token>();

  // Set up the providers
  final apiProvider = ApiProvider(
      baseUrl: GlobalConfiguration().appConfig['ApiSettings']['BaseUrl']
          ['Remote']);

  // Set up the controllers
  final settingsController = SettingsController(SettingsService());

  final AuthController authController =
      AuthController(AuthModel(apiProvider, token));
  final boardController = BoardController(BoardModel());

  // Initialize the CameraManager
  if (Platform.isAndroid || Platform.isIOS) {
    CameraManager().initialize();
  }
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  await Settings.init(cacheProvider: SharePreferenceCache());
  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthState()),
        ChangeNotifierProvider(create: (context) => ArtifactState()),
        ChangeNotifierProvider(create: (context) => UserState()),
        Provider(create: (context) => apiProvider),
      ],
      child: MyApp(
          settingsController: settingsController,
          authController: authController, boardController: boardController,)));
}
