// views/linear_board.dart

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/singletons/token.dart';
import '../../../controllers/linear_board_controller.dart';
import '_long_press_option_wheel.dart';
import '../../../utilities/audio/artefact_sound_player.dart';


class LinearBoard extends StatefulWidget {
  final Color? backgroundColor;
  final LinearBoardController linearBoardController;

  const LinearBoard({
    super.key,
    this.backgroundColor,
    required this.linearBoardController,
  });

  @override
  createState() => LinearBoardState();
}

class LinearBoardState extends State<LinearBoard>
    with TickerProviderStateMixin, ArtefactSoundPlayer {
  late LinearBoardController _linearBoardController;

  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;
  bool _showDeleteHover = false;
  bool _isDraggingOverTrashCan = false;
  bool _isPlayingAllSounds = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _linearBoardController = widget.linearBoardController;

    _linearBoardController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    cleanupArtefactSounds();
    super.dispose();
  }

  /// Play audio for artefact if it has sound attached
  Future<void> _playArtefactAudio(BoardArtefact artefact) async {
    if (artefact.baseArtefact?.artefactId == null) return;
    
    try {
      final token = GetIt.instance.get<Token>().value;
      if (token == null) return;

      final artefactId = artefact.baseArtefact!.artefactId!;
      final audioUrl = 'Remote/Users/Artefacts/$artefactId/play-audio';
      
      print('Debug: Playing audio for artefact $artefactId');
      
      // Set the audio source to the backend endpoint
      await _audioPlayer.setUrl(audioUrl, headers: {
        'Authorization': 'Bearer $token',
      });
      
      // Play the audio
      await _audioPlayer.play();
      print('Debug: Audio playback started successfully');
      
    } catch (e) {
      print('Debug: Error playing artefact audio: $e');
      // Don't show error to user, just log it - this is optional functionality
    }
  }

  /// Play all artefact sounds on the board sequentially
  Future<void> _playAllArtefactSounds() async {
    if (_isPlayingAllSounds) {
      // If already playing, stop the current playback
      await _audioPlayer.stop();
      setState(() {
        _isPlayingAllSounds = false;
      });
      return;
    }

    setState(() {
      _isPlayingAllSounds = true;
    });

    print('Debug: LinearBoard - Total artefacts on board: ${_linearBoardController.artifacts.length}');
    
    // Debug each artefact
    for (var artifact in _linearBoardController.artifacts) {
      if (artifact != null) {
        print('Debug: LinearBoard - Artefact ID: ${artifact.baseArtefact?.artefactId}, soundUrl: ${artifact.baseArtefact?.soundUrl}');
      }
    }
    
    final artefacts = _linearBoardController.artifacts
        .where((artifact) => artifact?.baseArtefact?.soundUrl?.isNotEmpty == true)
        .toList();

    if (artefacts.isEmpty) {
      print('Debug: LinearBoard - No artefacts with sound found on the board');
      setState(() {
        _isPlayingAllSounds = false;
      });
      return;
    }

    print('Debug: Playing ${artefacts.length} artefact sounds sequentially');

    try {
      for (var boardArtefact in artefacts) {
        if (boardArtefact != null && _isPlayingAllSounds) {
          try {
            final token = GetIt.instance.get<Token>().value;
            
            if (token != null) {
              final audioUrl = 'http://localhost:5192/api/Users/Artefacts/${boardArtefact.baseArtefact!.artefactId}/play-audio';
              print('Debug: Playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
              
              // Fetch audio data with proper authentication
              final response = await http.get(
                Uri.parse(audioUrl),
                headers: {
                  'Authorization': 'Bearer $token',
                },
              );
              
              if (response.statusCode == 200) {
                // Set audio source from bytes and play
                await _audioPlayer.setAudioSource(
                  AudioSource.uri(Uri.dataFromBytes(response.bodyBytes, mimeType: 'audio/mpeg')),
                );
                await _audioPlayer.play();
              } else {
                print('Debug: Failed to fetch audio - Status: ${response.statusCode}');
                continue; // Skip to next artefact
              }
              
              // Wait for the audio to complete before playing the next one
              await _audioPlayer.playerStateStream
                  .firstWhere((state) => state.processingState == ProcessingState.completed);
              
              print('Debug: Finished playing sound for artefact ${boardArtefact.baseArtefact!.artefactId}');
            }
          } catch (e) {
            print('Debug: Error playing sound for artefact ${boardArtefact.baseArtefact?.artefactId}: $e');
            // Continue to next artefact even if this one fails
          }
        }
      }
    } finally {
      setState(() {
        _isPlayingAllSounds = false;
      });
    }
    
    print('Debug: Finished playing all artefact sounds');
  }

  /// Confirmation dialog for removing all artifacts on the board
  void confirmRemoveAllArtifacts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                _linearBoardController.removeAllArtifacts();
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Display a message to the user that the board is full
  void showBoardFullDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text("Board is full."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Helper function for enabling the trashcan animation
  void _enableTrashcanAnimation() {
    setState(() {
      _showDeleteHover = true;
      _isDraggingOverTrashCan = true;
    });
    _animationController.forward();
  }

  /// Helper function for disabling the animation
  void _disableTrashcanAnimation() {
    _animationController.reverse();
    _isDraggingOverTrashCan = false;
    // Listen for the animation status
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        // Wait until animation is fully reversed
        setState(() {
          _showDeleteHover = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGrid(context),
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Play sounds for all artifacts in order
                    final artifacts = _linearBoardController.artifacts
                        .where((a) => a != null && a.baseArtefact != null)
                        .map((a) => a!.baseArtefact!)
                        .toList();
                    playArtefactSoundsInOrder(artifacts);
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play All Sounds'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
            _buildInteractiveTrashcan(context),
          ],
        ),

      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: widget.backgroundColor ??
              const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < _linearBoardController.fieldCount; i++) ...[
                  _buildBox(context, _linearBoardController.artifacts[i], i),
                  if (i < _linearBoardController.fieldCount - 1)
                    _buildVerticalDivider(context),
                ]
              ],
            ),
            // NOTE: boxes are already added inside the Row above. Avoid
            // duplicating them here, which would place Expanded widgets
            // directly under a Stack (invalid ParentData usage).
          ],
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, BoardArtefact? artifact, int index) {
    double artifactWidth = MediaQuery.of(context).size.width * 0.2;
    double artifactHeight = MediaQuery.of(context).size.height * 0.4;

    return Expanded(
      child: DragTarget<BoardArtefact>(
        onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) {
          int currentIndex =
              _linearBoardController.artifacts.indexOf(details.data);
          if (currentIndex != -1) {
            _linearBoardController.moveArtifact(currentIndex, index);
          }
        },
        builder: (BuildContext context, List<BoardArtefact?> candidateData,
            List<dynamic> rejectedData) {
          return Padding(
            padding: EdgeInsets.all(5),
            child: SizedBox(
              width: artifactWidth,
              height: artifactHeight,
              child: artifact == null
                  ? null
                  : _buildDraggableArtifact(
                      context, artifact, index, artifactWidth, artifactHeight),
            ),
          );
        },
      ),
    );
  }

   Widget _buildDraggableArtifact(BuildContext context, BoardArtefact artifact,
      int index, double artifactWidth, double artifactHeight) {
    return Draggable<BoardArtefact>(
      data: artifact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: artifactWidth / (_linearBoardController.fieldCount / 4),
            height: artifactHeight,
            child: artifact.content,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.1,
        child: artifact.content,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: artifact.content,
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      width: 1,
      color: Colors.grey,
    );
  }

  Widget _buildInteractiveTrashcan(BuildContext context) {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Stack(alignment: Alignment.center, children: [
          SlideTransition(
            position: _offsetAnimation,
            child: _showDeleteHover
                ? buildTrashCan(
                    height: 30,
                    width: 30,
                    color: const Color.fromARGB(255, 235, 32, 18),
                  )
                : SizedBox.shrink(),
          ),
          GestureDetector(
            onTap: () {
              confirmRemoveAllArtifacts();
            },
            child: DragTarget<BoardArtefact>(
              onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) {
                int artifactIndex =
                    _linearBoardController.artifacts.indexOf(details.data);
                if (artifactIndex != -1) {
                  _linearBoardController.removeArtifact(artifactIndex);
                }
                _disableTrashcanAnimation();
              },
              onWillAcceptWithDetails: (details) {
                _enableTrashcanAnimation();
                return true;
              },
              onLeave: (details) {
                _disableTrashcanAnimation();
              },
              builder: (BuildContext context,
                  List<BoardArtefact?> candidateData,
                  List<dynamic> rejectedData) {
                return Container(
                  // Defined size to increase target area
                  width: 200,
                  height: 120,
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: buildTrashCan(
                    height: _isDraggingOverTrashCan ? 120 : 50,
                    width: _isDraggingOverTrashCan ? 120 : 50,
                  ),
                );
              },
            ),
          ),
        ]));
  }

  Widget buildTrashCan(
      {double width = 50,
      double height = 50,
      Color color = const Color(0xFFF0F2D9)}) {
    return Stack(children: [
      Container(
        width: width,
        height: width,
        decoration: ShapeDecoration(
          color: color,
          shape: const OvalBorder(),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            )
          ],
        ),
        child: Center(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/icons/trash_bin.png'),
                fit: BoxFit.scaleDown,
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
