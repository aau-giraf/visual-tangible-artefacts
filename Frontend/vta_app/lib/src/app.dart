import 'package:flutter/material.dart';
import 'package:vta_app/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/ui/screens/welcome_screen.dart';
import 'package:vta_app/src/ui/screens/remote_board_screen.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/ui/screens/calling_screen.dart';
import 'package:vta_app/src/views/login_view.dart';
import 'package:vta_app/src/views/splash_view.dart';
import 'package:vta_app/theme/app_theme.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'package:vta_app/src/ui/screens/remote_session_screen.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp(
      {super.key,
      required this.settingsController,
      required this.authController,
      required this.artifactController});

  final SettingsController settingsController;

  final AuthController authController;

  final ArtefactController artifactController;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    
    // Glue the SettingsController to the MaterialApp.
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Only rebuild theme-related parts, not the entire app structure.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          key: const ValueKey('MaterialApp'), // Stable key to preserve Navigator state
          initialRoute: SplashView.routeName,
          navigatorKey: navigatorKey,
          theme: ThemeData(
            inputDecorationTheme: AppTheme.getInputDecorationTheme(context),
          ),
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) {
            try {
              return AppLocalizations.of(context)?.appTitle ?? 'VTA App';
            } catch (e) {
              return 'VTA App';
            }
          },

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          // theme: ThemeData(),
          // darkTheme: ThemeData.dark(),
          // themeMode: ThemeMode.light,

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SplashView.routeName:
                    return SplashView(controller: authController);
                  case LoginView.routeName:
                    return LoginView(controller: authController);
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case WelcomeScreen.routeName:
                    return WelcomeScreen(
                      authController: authController,
                      artifactController: artifactController,
                      settingsController: settingsController,
                    );
                  case ArtifactBoardScreen.routeName:
                    return ArtifactBoardScreen(
                      artifactController: artifactController,
                      authController: authController,
                      settingsController: settingsController,
                    );
                  case RemoteSessionScreen.routeName:
                    return const RemoteSessionScreen();
                  // ← ADD THIS CASE
                  case CallingScreen.routeName:
                    return const CallingScreen();
                  case RemoteBoardScreen.routeName:
                    return RemoteBoardScreen(
                      artifactController: artifactController,
                      settingsController: settingsController,
                    );
                  case VideoCallScreen.routeName:
                    final args =
                        routeSettings.arguments as Map<String, dynamic>?;
                    if (args == null) {
                      return SplashView(controller: authController);
                    }
                    return VideoCallScreen(
                      hubConnection: args['hubConnection'],
                      sessionId: args['sessionId'],
                      myUserId: args['myUserId'],
                      remoteUserId: args['remoteUserId'],
                      isCaller: args['isCaller'],
                      returnFromBoard: args['returnFromBoard'] ?? false,
                    );
                  default:
                    return SplashView(controller: authController);
                }
              },
            );
          },
        );
      },
    );
  }
}
