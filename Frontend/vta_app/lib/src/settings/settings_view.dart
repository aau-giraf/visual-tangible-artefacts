import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_controller.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'package:vta_app/src/ui/screens/take_picture_screen.dart';
import 'package:logging/logging.dart';


final _log = Logger('SettingsView');
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
        body: ListenableBuilder(
          listenable: controller,
          builder: (context, child) {
            return ListView(
              children: [
                buildProfilePicture(context),
                buildTextUnderImages(),
                buildLinearArtifactCount() /*, buildLanguage()*/
              ],
            );
          },
        ));
  }

  Future<void> _onToggleTextUnderImages(bool value) async {
    await controller.updateTextUnderImages(value);
  }

  Future<void> _onChangeLinearArtifactCount(int value) async {
    int linearArtifactCount = value;
    await controller.updateLinearArtifactCount(linearArtifactCount);
  }

  /* Future<void> _onToggleLocalization(int? value) async {
    await controller.updateLocalization(Localization.values[value ?? 0]);
  } */

  Widget buildProfilePicture(BuildContext context) {
    return _ProfilePictureSettingsTile();
  }

  Widget buildTextUnderImages() {
    return SwitchSettingsTile(
      settingKey: 'textUnderImagesSwitch',
      defaultValue: controller.textUnderImages,
      title: 'Text under billeder',
      subtitle: 'Vis billed navne over billeder',
      leading: Icon(Icons.text_fields),
      onChange: _onToggleTextUnderImages,
    );
  }

  Widget buildLinearArtifactCount() {
    return DropDownSettingsTile(
      settingKey: 'linearArtifactCount',
      title: 'Antal lineære artifakter',
      subtitle: 'Mængde af artifakter i lineær board',
      selected:
          controller.linearArtifactCount, // Use value from controller/database
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

class _ProfilePictureSettingsTile extends StatefulWidget {
  @override
  State<_ProfilePictureSettingsTile> createState() =>
      _ProfilePictureSettingsTileState();
}

class _ProfilePictureSettingsTileState
    extends State<_ProfilePictureSettingsTile> {
  Uint8List? _profilePictureBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
  }

  Future<void> _loadProfilePicture() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // First check for base64 encoded image
      final base64Image = prefs.getString('profilePicture');
      if (base64Image != null) {
        try {
          final bytes = base64Decode(base64Image);
          if (mounted) {
            setState(() {
              _profilePictureBytes = bytes;
              _isLoading = false;
            });
          }
          return;
        } catch (e) {
          _log.fine('Error decoding base64 image: $e');
        }
      }
      // Fallback to file path if base64 not found
      final imagePath = prefs.getString('profilePicturePath');
      if (imagePath != null) {
        // If it's a local file path, load it
        if (imagePath.startsWith('/') || imagePath.contains('\\')) {
          final file = File(imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            if (mounted) {
              setState(() {
                _profilePictureBytes = bytes;
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _log.fine('Error loading profile picture: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfilePicture(Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store the bytes as base64 for simplicity
      final base64String = base64Encode(bytes);
      await prefs.setString('profilePicture', base64String);
      await prefs.setString('profilePictureSet', 'true');

      if (mounted) {
        setState(() {
          _profilePictureBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilbillede opdateret'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _log.fine('Error saving profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved gemning af billede: $e')),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        await _saveProfilePicture(result.files.single.bytes!);
      }
    } catch (e) {
      _log.fine('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fejl ved valg af billede: $e')),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (CameraManager().cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingen kamera tilgængelig'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TakePictureScreen(
            camera: CameraManager().cameras.first,
            onImageChosen: (bytes) async {
              final nav = Navigator.of(context);
              await _saveProfilePicture(bytes);
              if (mounted) {
                nav.pop();
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _showImagePickerDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vælg profilbillede'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Vælg fra galleri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tag billede'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: _showImagePickerDialog,
          child: Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 2,
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : ClipOval(
                        child: _profilePictureBytes != null
                            ? Image.memory(
                                _profilePictureBytes!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        title: const Text('Profilbillede'),
        subtitle: const Text('Tryk for at ændre dit profilbillede'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _showImagePickerDialog,
      ),
    );
  }
}
