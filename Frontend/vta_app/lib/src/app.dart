import 'package:flutter/material.dart';
import 'package:vta_app/src/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/ui/screens/remote_board_screen.dart';
import 'package:vta_app/src/views/login_view.dart';
import 'package:vta_app/src/views/splash_view.dart';
import 'package:vta_app/theme/app_theme.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'functions/auth.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          theme: ThemeData(
            inputDecorationTheme: AppTheme.inputDecorationTheme,
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
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
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
                  case ArtifactBoardScreen.routeName:
                    return ArtifactBoardScreen(
                      artifactController: artifactController,
                      authController: authController,
                      settingsController: settingsController,
                    );
                  case RemoteSessionScreen.routeName:
                    return const RemoteSessionScreen();
                  case RemoteBoardScreen.routeName:
                    return RemoteBoardScreen(
                      artifactController: artifactController,
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
