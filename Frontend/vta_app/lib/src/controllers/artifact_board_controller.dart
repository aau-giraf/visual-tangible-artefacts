import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/linear_board_controller.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/settings/settings_service.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';

typedef VoidCallback = void Function();

class ArtifactBoardController {
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
  final VoidCallback notifyView;

  // Constructor
  ArtifactBoardController({required this.notifyView}) {
    // Initialize keys
    talkingMatKey = GlobalKey<TalkingMatState>();
    linearBoardKey = GlobalKey<LinearBoardState>();

    // Initialize controllers
    talkingmatController = TalkingmatController(onArtefactAdded: _playArtefactAudio);
    linearBoardController = LinearBoardController(
      artifacts: [],
      fieldCount: 0,
      onArtefactAdded: _playArtefactAudio,
    );

    // Setup TalkingMat and LinearBoard
    talkingMat = TalkingMat(
      key: talkingMatKey,
      artifacts: [],
      controller: talkingmatController,
    );
    linearBoard = LinearBoard(
      key: linearBoardKey,
      linearBoardController: linearBoardController,
    );

    // Initialize configuration
    _setupLinearBoardController();
    getCurrentBoardStatus();
  }

  /// Function to play audio when an artefact is added to the board
  void _playArtefactAudio(BoardArtefact boardArtefact) async {
    if (boardArtefact.baseArtefact?.soundUrl?.isNotEmpty == true) {
      try {
        final token = GetIt.instance.get<Token>().value;
        final apiProvider = GetIt.instance.get<ApiProvider>();
        
        if (token != null) {
          final response = await http.get(
            Uri.parse('${apiProvider.baseUrl}Users/Artefacts/${boardArtefact.baseArtefact!.artefactId}/play-audio'),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );
          
          if (response.statusCode == 200) {
            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/mpeg')),
            );
            await _audioPlayer.play();
            print('Audio playback started successfully for artefact: ${boardArtefact.baseArtefact!.artefactId}');
          } else {
            print('Failed to load audio: ${response.statusCode}');
          }
        }
      } catch (e) {
        print('Error playing artefact audio: $e');
      }
    }
  }

  /// Function for setting up the linear board
  void _setupLinearBoardController() async {
    // Get the count of fields from settings
    int? count = await SettingsService().linearArtifactCount() ?? 4;
    // If count is not current count, update controller
    if (count != linearBoardFieldCount) {
      linearBoardFieldCount = count;
      // Update the controller with new artifact list and field count
      linearBoardController.artifacts =
      List<BoardArtefact?>.filled(linearBoardFieldCount!, null, growable: false);
      linearBoardController.fieldCount = linearBoardFieldCount!;
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
        print('Debug: ArtifactBoardController - Total artefacts on linear board: ${linearBoardController.artifacts.length}');
        
        // Debug each artefact
        for (var artifact in linearBoardController.artifacts) {
          if (artifact != null) {
            print('Debug: ArtifactBoardController - Linear Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
          }
        }
        
        artefacts = linearBoardController.artifacts
            .where((artifact) => artifact?.baseArtefact?.soundUrl?.isNotEmpty == true)
            .cast<BoardArtefact>()
            .toList();
      } else {
        // Talking mat
        print('Debug: ArtifactBoardController - Total artefacts on talking mat: ${talkingmatController.value.length}');
        
        // Debug each artefact
        for (var artifact in talkingmatController.value) {
          print('Debug: ArtifactBoardController - TalkingMat Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
        }
        
        artefacts = talkingmatController.value
            .where((artifact) => artifact.baseArtefact?.soundUrl?.isNotEmpty == true)
            .toList();
      }

      if (artefacts.isEmpty) {
        print('Debug: ArtifactBoardController - No artefacts with sound found on the board');
        _isPlayingAllSounds = false;
        notifyView();
        return;
      }

      print('Debug: ArtifactBoardController - Playing ${artefacts.length} artefact sounds sequentially');

      for (var boardArtefact in artefacts) {
        if (_isPlayingAllSounds) {
          try {
            final token = GetIt.instance.get<Token>().value;
            final apiProvider = GetIt.instance.get<ApiProvider>();
            
            if (token != null) {
              final audioUrl = '${apiProvider.baseUrl}Users/Artefacts/${boardArtefact.baseArtefact!.artefactId}/play-audio';
              print('Debug: ArtifactBoardController - Playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              
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
                
                print('Debug: ArtifactBoardController - Finished playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              }
            }
          } catch (e) {
            print('Debug: ArtifactBoardController - Error playing sound for artefact ${boardArtefact.baseArtefact?.artefactId}: $e');
            // Continue to next artefact even if this one fails
          }
        }
      }
    } finally {
      _isPlayingAllSounds = false;
      notifyView();
    }
    
    print('Debug: ArtifactBoardController - Finished playing all artefact sounds');
  }

  /// Dispose of resources
  void dispose() {
    _audioPlayer.dispose();
  }
}
