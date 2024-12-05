import 'package:flutter/cupertino.dart';
import 'package:vta_app/src/controllers/linear_board_controller.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';
import 'package:vta_app/src/settings/settings_service.dart';
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
  final TalkingmatController talkingmatController = TalkingmatController();
  late LinearBoardController linearBoardController;
  int? linearBoardFieldCount;

  // Callback to notify the view to update UI
  final VoidCallback notifyView;

  // Constructor
  ArtifactBoardController({required this.notifyView}) {
    // Initialize keys
    talkingMatKey = GlobalKey<TalkingMatState>();
    linearBoardKey = GlobalKey<LinearBoardState>();

    // Initialize LinearBoardController
    linearBoardController = LinearBoardController(
      artifacts: [],
      fieldCount: 0,
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
}