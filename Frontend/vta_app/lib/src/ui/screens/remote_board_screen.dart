import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/remote_artifact_board_controller.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/services/video_call_manager.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:get_it/get_it.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/board/quick_add_artefact.dart';
import '../widgets/categories/categories_widget.dart' as categories_widget;
import '../widgets/video/pip_video_widget.dart';
import 'video_call_screen.dart';

class RemoteBoardScreen extends StatefulWidget {
  static const String routeName = "/remote-board";

  const RemoteBoardScreen({
    super.key,
    this.artifactController,
    this.boardController,
    required this.settingsController,
  });

  final ArtefactController? artifactController;
  final ArtifactBoardController? boardController;
  final SettingsController settingsController;

  @override
  State<RemoteBoardScreen> createState() => _RemoteBoardScreenState();
}

class _RemoteBoardScreenState extends State<RemoteBoardScreen> {
  late RemoteArtifactBoardController controller;
  String sessionId = '';
  String boardId = '';
  bool isOwner = false;
  bool _isInitialized = false;
  bool _hasVideo = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        sessionId = args['sessionId'] as String;
        boardId = args['boardId'] as String;
        _hasVideo = args['hasVideo'] as bool? ?? false;
      } else {
        // Fallback: extract session ID if passed as string
        sessionId = args is String ? args : '';
        boardId = '';
      }

      // Determine if current user is the owner
      // The person being called (child) should have control, not the caller (caregiver)
      final currentUserId = SignalRService().currentUserId;
      final initiatorId = SignalRService().sessionInitiatorId;
      isOwner = currentUserId != initiatorId;

      debugPrint(
          "RemoteBoard => sessionId=$sessionId, boardId=$boardId, isOwner=$isOwner, currentUser=$currentUserId, initiator=$initiatorId");

      // For owner: use their existing board controller if available
      // For non-owner: create a new empty controller
      final existingController = isOwner ? widget.boardController : null;

      controller = RemoteArtifactBoardController(
        sessionId: sessionId,
        isOwner: isOwner,
        notifyView: () {
          if (mounted) setState(() {});
        },
        existingController: existingController,
        settingsController: widget.settingsController,
      );
      
      // Listen for remote hang-up
      SignalRService().onSessionEnded = () async {
        debugPrint('[RemoteBoard] Remote user ended the session');
        if (mounted) {
          VideoCallManager().endCall();
          
          // Caller (non-owner) is navigated to contacts list
          // Called (owner) is navigated to their board
          if (!isOwner) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/remote',
              (route) => false,
            );
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/artifact-board',
              (route) => false,
            );
          }
        }
      };
      
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Navigate back to full video call screen
  void _goToVideoScreen() {
    final videoManager = VideoCallManager();
    if (!videoManager.isCallActive) return;

    Navigator.of(context).pushReplacementNamed(
      VideoCallScreen.routeName,
      arguments: {
        'hubConnection': SignalRService().hubConnection!,
        'sessionId': sessionId,
        'myUserId': SignalRService().currentUserId!,
        'remoteUserId': SignalRService().remoteUserId ?? 'unknown',
        'isCaller': SignalRService().currentUserId == SignalRService().sessionInitiatorId,
        'returnFromBoard': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double padding = 5;
    double screenHeight = MediaQuery.of(context).size.height;
    double categoriesWidgetHeight = 60;
    double dividerHeight = 5;

    // Get artifact controller if provided, otherwise try to get from GetIt
    final artefactController = widget.artifactController ??
        (GetIt.instance.isRegistered<ArtefactController>()
            ? GetIt.instance.get<ArtefactController>()
            : null);

    // If artefactController exists but categories haven't been loaded yet, load them
    if (artefactController != null && artefactController.categories == null) {
      return FutureBuilder(
        future: artefactController.updateArtifacts(context: context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.white,
                ),
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            // Categories loaded, rebuild with the actual screen
            return _buildRemoteBoardScreen(
              context,
              padding,
              screenHeight,
              categoriesWidgetHeight,
              dividerHeight,
              artefactController,
            );
          }
          return const Scaffold(body: SizedBox.shrink());
        },
      );
    }

    return _buildRemoteBoardScreen(
      context,
      padding,
      screenHeight,
      categoriesWidgetHeight,
      dividerHeight,
      artefactController,
    );
  }

  Widget _buildRemoteBoardScreen(
    BuildContext context,
    double padding,
    double screenHeight,
    double categoriesWidgetHeight,
    double dividerHeight,
    ArtefactController? artefactController,
  ) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isOwner ? "Styring" : "Visning"),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            color: Colors.red,
            onPressed: () async {
              debugPrint('[RemoteBoard] Hang-up button pressed');
              await SignalRService().endSession();
              await VideoCallManager().endCall();
              if (mounted) {
                // Caller (non-owner) is navigated to contacts list
                // Called (owner) is navigated to their board
                if (!isOwner) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/remote',
                    (route) => false,
                  );
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/artifact-board',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Center(
                          child: controller.showDirectional
                              ? controller.linearBoard!
                              : (isOwner
                                  ? controller.ownerTalkingMat!
                                  : controller.talkingMat!),
                        ),
                      ),
                      if (isOwner) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: RelationalBoardButton(
                              onPressed: () {
                                controller.switchBoard();
                              },
                              icon: controller.showDirectional
                                  ? const Icon(
                                      IconData(0xf685,
                                          fontFamily: 'MaterialIcons'),
                                      size: 24.0,
                                    )
                                  : const Icon(
                                      IconData(0xf601,
                                          fontFamily: 'MaterialIcons'),
                                      size: 24.0,
                                    ),
                            ),
                          ),
                        ),
                        if (artefactController != null)
                          QuickAddArtefactButton(
                            artefactController: artefactController,
                            onArtifactAdded: controller.addArtifact,
                          ),
                      ],
                      const QuickChatButton(),
                      
                      // Picture-in-Picture video widget
                      if (VideoCallManager().isCallActive && VideoCallManager().remoteRenderer != null)
                        PipVideoWidget(
                          remoteRenderer: VideoCallManager().remoteRenderer!,
                          onTap: _goToVideoScreen,
                        ),
                    ],
                  ),
                ),
              ),
              if (isOwner && artefactController != null)
                Padding(
                  padding: EdgeInsets.only(left: padding, right: padding),
                  child: SizedBox(
                    height: categoriesWidgetHeight,
                    child: categories_widget.CategoriesWidget(
                      widgetHeight: categoriesWidgetHeight,
                      onArtifactAdded: controller.addArtifact,
                      artefactController: artefactController,
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }
}
