import 'package:flutter/material.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/models/login_form.dart';
import 'package:vta_app/src/models/login_response.dart';
import 'package:vta_app/src/models/user.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'dart:convert';
import 'src/app.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';
import 'package:global_configuration/global_configuration.dart';

void main() async {
  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  //Load global configuration from assets/cfg/app_settings.json
  //await GlobalConfiguration().loadFromAsset("app_settings");
  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(MyApp(settingsController: settingsController));
}
//Jeg elsker tissemand