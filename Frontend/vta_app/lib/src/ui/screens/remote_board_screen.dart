import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/remote_artifact_board_controller.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/services/signalr_service.dart';
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
  });

  final ArtefactController? artifactController;
  final ArtifactBoardController? boardController;

  @override
  State<RemoteBoardScreen> createState() => _RemoteBoardScreenState();
}

class _RemoteBoardScreenState extends State<RemoteBoardScreen> {
  late RemoteArtifactBoardController controller;
  late String sessionId;
  late bool isOwner;

  @override
  void initState() {
    super.initState();

    // Get sessionId from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as String? ?? '';
      sessionId = args;

      // Determine if current user is the owner (initiator)
      final currentUserId = SignalRService().currentUserId;
      final initiatorId = SignalRService().sessionInitiatorId;
      isOwner = currentUserId == initiatorId;

      debugPrint(
          "RemoteBoard => sessionId=$sessionId, isOwner=$isOwner, currentUser=$currentUserId, initiator=$initiatorId");

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
      );
    });
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
