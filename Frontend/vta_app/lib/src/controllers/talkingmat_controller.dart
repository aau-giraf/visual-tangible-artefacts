import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';

class TalkingmatController extends ValueNotifier<List<BoardArtefact>> {
  final Function(BoardArtefact)? onArtefactAdded;
  
  TalkingmatController({List<BoardArtefact>? initialArtifacts, this.onArtefactAdded})
      : super(initialArtifacts ?? []);

  void addArtifact(BoardArtefact artefact) {
    value.add(artefact);
    onArtefactAdded?.call(artefact);
    notifyListeners();
  }

  /// Set the visibility of the name label for all artefacts currently on the board.
  /// This affects both in-memory board instances AND updates the backend ARTEFACT table.
  void setNamesVisibleForAll(bool visible) {
    bool changed = false;
    for (final artefact in value) {
      if (artefact.nameVisible != visible) {
        artefact.nameVisible = visible;
        changed = true;
        
        // Also update the base ARTEFACT table's nameShown field
        _updateBaseArtefactNameShown(artefact.artefactId, visible);
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  /// Update the base ARTEFACT table's nameShown field via backend API
  Future<void> _updateBaseArtefactNameShown(String artefactId, bool nameShown) async {
    try {
      final token = GetIt.instance.get<Token>().value;
      final apiProvider = GetIt.instance.get<ApiProvider>();
      
      if (token == null) {
        print('Debug: No token available for updating base artefact $artefactId');
        return;
      }

      // Decode user ID from JWT token
      final decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['id'] as String?;
      
      if (userId == null) {
        print('Debug: Could not extract user ID from token');
        return;
      }

      // Create form data for the PATCH request
      final formData = <String, dynamic>{
        'ArtefactId': artefactId,
        'UserId': userId,
        'NameShown': nameShown,
      };

      final response = await apiProvider.sendAsMultiPart(
        'PATCH',
        'Users/Artefacts',
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: formData,
      );

      if (response?.statusCode == 200) {
        print('Debug: Successfully updated base artefact $artefactId nameShown to $nameShown');
      } else {
        print('Debug: Failed to update base artefact $artefactId nameShown. Status: ${response?.statusCode}');
      }
    } catch (e) {
      print('Debug: Error updating base artefact $artefactId nameShown: $e');
    }
  }

  void removeArtifact(BoardArtefact artefact) {
    // Prefer removing by savedArtefactId (instance id) to avoid removing all duplicates
    if (artefact.savedArtefactId != null) {
      value.removeWhere((item) => item.savedArtefactId == artefact.savedArtefactId);
    } else {
      // Fallback: remove a single instance matching the artefactId
      final idx = value.indexWhere((item) => item.artefactId == artefact.artefactId);
      if (idx != -1) {
        value.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void removeAllArtifacts({BuildContext? context}) {
    if (context != null && context.mounted) {
      _showRemoveAllArtifactsAlert(context);
    }
  }

  void _showRemoveAllArtifactsAlert(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Confirm"),
            content: Text("Are you sure you want to remove all artifacts?"),
            actions: <Widget>[
              TextButton(
                child: Text("Cancel"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: Text("Yes"),
                onPressed: () {
                  value.clear();
                  Navigator.of(context).pop(); // Close the dialog
                  notifyListeners();
                },
              ),
            ],
          );
        });
  }
}
