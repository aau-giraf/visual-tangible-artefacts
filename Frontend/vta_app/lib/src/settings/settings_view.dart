import 'package:flutter/material.dart';
import 'package:vta_app/src/utilities/extensions/string_extension.dart';
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
          children: [buildTextUnderImages(), buildLinearArtifactCount()/*, buildLanguage()*/],
        ));
  }

  Future<void> _onToggleTextUnderImages(bool value) async {
    await controller.updateTextUnderImages(value);
  }

  Future<void> _onChangeLinearArtifactCount(int value) async {
    int linearArtifactCount = value;
    await controller.updateLinearArtifactCount(linearArtifactCount);
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

  Widget buildLinearArtifactCount() {
    return DropDownSettingsTile(
      settingKey: 'linearArtifactCount',
      title: 'Antal lineære artifakter',
      subtitle: 'Mængde af artifakter i lineær board',
      selected: 4, // Default value
      values: <int, String>{
        2: '2',
        4: '4',
        6: '6',
        8: '8',
      },
      leading: Icon(IconData(0xf601, fontFamily: 'MaterialIcons')),
      onChange: _onChangeLinearArtifactCount,
    );
  }

/*
  Widget buildLanguage() {
    return DropDownSettingsTile(
      title: "Sprog",
      settingKey: "languageSetting",
      selected: controller.localization.index,
      leading: Icon(Icons.language),
      values: Map.fromEntries(Localization.values
          .map((e) => MapEntry(e.index, e.name.capitalize()))),
      onChange: _onToggleLocalization,
    );
  }*/
}
