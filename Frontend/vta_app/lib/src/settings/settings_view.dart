import 'package:flutter/material.dart';
import 'settings_controller.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

/// Displays the various settings that can be customized by the user.
///
/// When a user changes a setting, the SettingsController is updated and
/// Widgets that listen to the SettingsController are rebuilt.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.controller});

  static const routeName = '/settings';

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: ListView(
          children: [buildTextUnderImages(), buildLanguage()],
        ));
  }

  Future<void> _onToggleTextUnderImages(bool value) async {
    await controller.updateTextUnderImages(value);
  }

  Future<void> _onToggleLocalization(int? value) async {
    await controller.updateLocalization(Localization.values[value ?? 0]);
  }

  Widget buildTextUnderImages() {
    return SwitchSettingsTile(
      settingKey: 'textUnderImagesSwitch',
      title: 'Text under billeder',
      subtitle: 'Vis billed navne under billeder',
      leading: Icon(Icons.text_fields),
      onChange: _onToggleTextUnderImages,
    );
  }

  Widget buildLanguage() {
    return DropDownSettingsTile(
      title: "Sprog",
      settingKey: "languageSetting",
      selected: controller.localization.index,
      leading: Icon(Icons.language),
      values: Map.fromEntries(
          Localization.values.map((e) => MapEntry(e.index, e.name))),
      onChange: _onToggleLocalization,
    );
  }
}
