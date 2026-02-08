import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';

import 'package:vta_app/src/models/artefact_model.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/services/notification_service.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/app_logger.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'package:vta_app/src/services/sync_timer.dart';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/database/database_helper.dart';
import 'package:vta_app/src/database/database_debug_helper.dart';

final _log = Logger('Main');

Future<void> clearSharedPreferences() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();

  // Clear SharedPreferences, for testing
  // await clearSharedPreferences();

  try {
    // Load global configuration from assets/cfg/app_settings.json
    await GlobalConfiguration().loadFromAsset("app_settings");
  } catch (e) {
    _log.warning('Error loading configuration: $e');
    // Continue anyway - will use fallback URL
  }

  // Initialize SQLite database (only on mobile platforms, not web)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await DatabaseHelper.instance.database;
      _log.info('SQLite database initialized successfully');
      await DatabaseDebugHelper.printDatabasePath();
    } catch (e) {
      _log.severe('Failed to initialize SQLite database: $e');
    }
  }

  // Set up global token with GetIt
  GetIt.I.registerSingleton<Token>(Token());
  GetIt.I.registerSingleton<UserInfo>(UserInfo());
  var token = GetIt.I.get<Token>();
  var userInfo = GetIt.I.get<UserInfo>();

  // Set up the providers
  final apiProvider = ApiProvider(baseUrl: PlatformUtils.getApiUrl());
  GetIt.I.registerSingleton<ApiProvider>(apiProvider);

  final settingsController = SettingsController(SettingsService());
  final ArtefactController artifactController =
      ArtefactController(ArtifactModel(apiProvider));
  GetIt.I.registerSingleton<ArtefactController>(artifactController);

  final AuthController authController =
      AuthController(AuthModel(apiProvider, token, userInfo));

  // Initialize the CameraManager
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    CameraManager().initialize();
  }
  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();
  // Initialize Notification Service
  await NotificationService().initialize();

  await Settings.init(cacheProvider: SharePreferenceCache());

  // NOTE: Sync timer is started after user logs in
  // See login flow for SyncTimer().start()

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
        authController: authController,
        artifactController: artifactController,
      )));
}
