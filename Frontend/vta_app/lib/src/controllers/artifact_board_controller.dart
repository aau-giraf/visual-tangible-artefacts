import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/linear_board_controller.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/settings/settings_service.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/audio/artefact_sound_player.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';

typedef VoidCallback = void Function();

class ArtifactBoardController with ArtefactSoundPlayer {
  bool showDirectional = false;
  TalkingMat? talkingMat;
  LinearBoard? linearBoard;
  late GlobalKey<TalkingMatState> talkingMatKey;
  late GlobalKey<LinearBoardState> linearBoardKey;
  late final TalkingmatController talkingmatController;
  late LinearBoardController linearBoardController;
  int? linearBoardFieldCount;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAllSounds = false;

  // Getter for playing state
  bool get isPlayingAllSounds => _isPlayingAllSounds;

  // Callback to notify the view to update UI
  VoidCallback notifyView;
  final SettingsController settingsController;

  /// Update the notifyView callback (useful when widget is recreated)
  void updateNotifyView(VoidCallback newNotifyView) {
    notifyView = newNotifyView;
  }

  /// Play audio when an artefact is added to the board
  Future<void> _playArtefactAudio(BoardArtefact artifact) async {
    if (artifact.baseArtefact?.soundUrl != null && 
        artifact.baseArtefact!.soundUrl!.isNotEmpty) {
      try {
        await playArtefactSound(artifact.baseArtefact!);
      } catch (e) {
        debugPrint('Error playing artefact audio: $e');
      }
    }
  }

  // Constructor
  ArtifactBoardController({required this.notifyView, required this.settingsController}) {
    // Initialize keys
    talkingMatKey = GlobalKey<TalkingMatState>();
    linearBoardKey = GlobalKey<LinearBoardState>();

    // Initialize controllers
    talkingmatController = TalkingmatController(onArtefactAdded: _playArtefactAudio);
    debugPrint('[ArtifactBoardController] Created talkingmatController with ID: ${talkingmatController.hashCode}');
    
    // Initialize linearBoardController with default field count
    linearBoardFieldCount = 4; // Default value
    linearBoardController = LinearBoardController(
      artifacts: List<BoardArtefact?>.filled(linearBoardFieldCount!, null, growable: false),
      fieldCount: linearBoardFieldCount!,
      onArtefactAdded: _playArtefactAudio,
    );

    // Setup TalkingMat and LinearBoard
    talkingMat = TalkingMat(
      key: talkingMatKey,
      artifacts: [],
      controller: talkingmatController,
    );
    debugPrint('[ArtifactBoardController] Created talkingMat widget with controller ID: ${talkingmatController.hashCode}');
    linearBoard = LinearBoard(
      key: linearBoardKey,
      linearBoardController: linearBoardController,
    );
    debugPrint('[ArtifactBoardController] Created linearBoard widget: ${linearBoard != null}');

    // Initialize configuration (async - will update field count if different)
    _setupLinearBoardController();
    getCurrentBoardStatus();

    // Apply initial setting for text under images (default false)
    talkingmatController.setNamesVisibleForAll(settingsController.textUnderImages);
    // Listen for changes to settings and sync name visibility
    settingsController.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    // When the setting toggles, update all current artefacts' name visibility
    talkingmatController.setNamesVisibleForAll(settingsController.textUnderImages);
    // Sync linear board field count when setting changes
    linearBoardController.setFieldCount(settingsController.linearArtifactCount);
    // Optionally notify view in case other UI depends on settings 
    notifyView();
  }


  /// Function for setting up the linear board
  void _setupLinearBoardController() async {
    // Get the count of fields from settings
    int? count = await SettingsService().linearArtifactCount() ?? 4;
    // If count is not current count, update controller
    if (count != linearBoardFieldCount) {
      linearBoardFieldCount = count;
      // Update the controller with new field count, resizing the artifacts list
      linearBoardController.setFieldCount(linearBoardFieldCount!);
      notifyView();
    }
  }

  /// Get the current status of whether the board is at talking mat or directional
  void getCurrentBoardStatus() async {
    // Get status from settings
    bool? showDirectionalBoard = await SettingsService().showDirectionalBoard();
    // If the bool is not null or not equal to current, update status
    if (showDirectionalBoard != null && showDirectionalBoard != showDirectional) {
      showDirectional = showDirectionalBoard;
      notifyView();
    }
  }

  /// Switch the status of whether the board is at talking mat or directional
  void switchCurrentBoard() async {
    bool newStatus = !showDirectional;
    // Update the setting with SettingsService
    await SettingsService().updateShowDirectionalBoard(newStatus);
    showDirectional = newStatus;
    notifyView();
  }

  /// Add an artifact to the currently active board
  void addArtifactToCurrentBoard(BoardArtefact artifact) {
    // Apply current setting for name visibility to the new artefact before adding
    artifact.nameVisible = settingsController.textUnderImages;
    if (showDirectional) {
      linearBoardController.addArtifact(artifact);
    } else {
      talkingmatController.addArtifact(artifact);
    }
    notifyView();
  }

  /// Play all artefact sounds on the current board sequentially
  Future<void> playAllArtefactSounds() async {
    if (_isPlayingAllSounds) {
      // If already playing, stop the current playback
      await _audioPlayer.stop();
      _isPlayingAllSounds = false;
      notifyView();
      return;
    }

    _isPlayingAllSounds = true;
    notifyView();

    try {
      List<BoardArtefact> artefacts;
      
      // Get artefacts from the current board
      if (showDirectional) {
        // Linear board
        debugPrint('Debug: ArtifactBoardController - Total artefacts on linear board: ${linearBoardController.artifacts.length}');
        
        // Debug each artefact
        for (var artifact in linearBoardController.artifacts) {
          if (artifact != null) {
            debugPrint('Debug: ArtifactBoardController - Linear Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
          }
        }
        
        artefacts = linearBoardController.artifacts
            .where((artifact) => artifact?.baseArtefact?.soundUrl?.isNotEmpty == true)
            .cast<BoardArtefact>()
            .toList();
      } else {
        // Talking mat
        debugPrint('Debug: ArtifactBoardController - Total artefacts on talking mat: ${talkingmatController.value.length}');
        
        // Debug each artefact
        for (var artifact in talkingmatController.value) {
          debugPrint('Debug: ArtifactBoardController - TalkingMat Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
        }
        
        artefacts = talkingmatController.value
            .where((artifact) => artifact.baseArtefact?.soundUrl?.isNotEmpty == true)
            .toList();
      }

      if (artefacts.isEmpty) {
        debugPrint('Debug: ArtifactBoardController - No artefacts with sound found on the board');
        _isPlayingAllSounds = false;
        notifyView();
        return;
      }

      debugPrint('Debug: ArtifactBoardController - Playing ${artefacts.length} artefact sounds sequentially');

      for (var boardArtefact in artefacts) {
        if (_isPlayingAllSounds) {
          try {
            final token = GetIt.instance.get<Token>().value;
            final apiProvider = GetIt.instance.get<ApiProvider>();
            
            if (token != null) {
              final audioUrl = '${apiProvider.baseUrl}Users/Artefacts/${boardArtefact.baseArtefact!.artefactId}/play-audio';
              debugPrint('Debug: ArtifactBoardController - Playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              
              // Fetch the audio data
              final response = await http.get(
                Uri.parse(audioUrl),
                headers: {
                  'Authorization': 'Bearer $token',
                },
              );
              
              if (response.statusCode == 200) {
                // Set and play the audio
                await _audioPlayer.setAudioSource(
                  AudioSource.uri(Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/mpeg')),
                );
                
                await _audioPlayer.play();
                
                // Wait for the audio to complete before playing the next one
                await _audioPlayer.playerStateStream
                    .firstWhere((state) => state.processingState == ProcessingState.completed);
                
                debugPrint('Debug: ArtifactBoardController - Finished playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              }
            }
          } catch (e) {
            debugPrint('Debug: ArtifactBoardController - Error playing sound for artefact ${boardArtefact.baseArtefact?.artefactId}: $e');
            // Continue to next artefact even if this one fails
          }
        }
      }
    } finally {
      _isPlayingAllSounds = false;
      notifyView();
    }
    
    debugPrint('Debug: ArtifactBoardController - Finished playing all artefact sounds');
  }

  /// Dispose of resources
  void dispose() {
    try { settingsController.removeListener(_onSettingsChanged); } catch (_) {}
    _audioPlayer.dispose();
  }
}
