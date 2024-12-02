import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/models/auth_model.dart';
import 'package:vta_app/src/ui/screens/artifact_board_screen.dart';
import 'package:vta_app/src/views/login_view.dart';
import 'package:vta_app/src/views/splash_view.dart';
import 'package:vta_app/theme/app_theme.dart';
import 'sample_feature/sample_item_details_view.dart';
import 'sample_feature/sample_item_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'functions/auth.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
    required this.authController,
  });

  final SettingsController settingsController;

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          theme: ThemeData(
            inputDecorationTheme: AppTheme.inputDecorationTheme,
          ),
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
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
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

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
                  case ArtifactBoardScreen.routeName:
                    return ArtifactBoardScreen();
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
