import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/remote_artifact_board_controller.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/board/quick_add_artefact.dart';
import '../widgets/categories/categories_widget.dart' as categories_widget;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;

      // Handle both old string format and new map format
      if (args is Map<String, dynamic>) {
        sessionId = args['sessionId'] as String;
        boardId = args['boardId'] as String;
      } else if (args is String) {
        // Fallback for old code - won't work without boardId
        sessionId = args;
        boardId =
            'error-no-board-id'; // This will cause an error, which is intended
      } else {
        sessionId = '';
        boardId = 'error-no-board-id';
      }

      // Determine if current user is the owner (initiator)
      final currentUserId = SignalRService().currentUserId;
      final initiatorId = SignalRService().sessionInitiatorId;
      isOwner = currentUserId == initiatorId;

      debugPrint(
          "RemoteBoard => sessionId=$sessionId, boardId=$boardId, isOwner=$isOwner, currentUser=$currentUserId, initiator=$initiatorId");

      // For owner: use their existing board controller if available
      // For non-owner: create a new empty controller
      final existingController = isOwner ? widget.boardController : null;

      controller = RemoteArtifactBoardController(
        sessionId: sessionId,
        isOwner: isOwner,
        sharedBoardId: boardId,
        notifyView: () {
          if (mounted) setState(() {});
        },
        existingController: existingController,
        settingsController: widget.settingsController,
      );
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
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
        title: Text(isOwner ? "Styring" : "Visning"),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_end),
            onPressed: () async {
              await SignalRService().endSession();
              if (mounted) Navigator.of(context).pop();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SafeArea(
                bottom: false,
                child: Container(
                  height: screenHeight -
                      categoriesWidgetHeight -
                      MediaQuery.of(context).padding.top -
                      dividerHeight,
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Stack(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Center(
                          child: controller.showDirectional
                              ? controller.linearBoard!
                              : (isOwner
                                  ? TalkingMat(
                                      controller:
                                          controller.base.talkingmatController,
                                      onArtifactPositionChanged: (artifact) {
                                        controller.onArtifactPositionChanged(
                                            artifact);
                                      },
                                    )
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
                    ],
                  ),
                ),
              ),
              Divider(
                color: Colors.transparent,
                height: dividerHeight,
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
      ),
    );
  }
}
