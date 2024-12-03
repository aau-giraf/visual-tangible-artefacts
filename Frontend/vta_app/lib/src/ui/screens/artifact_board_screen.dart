import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/linear_board_controller.dart';
import 'package:vta_app/src/functions/auth.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/settings/settings_service.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/categories/categories_widget.dart'
    as categories_widget; // Aliased import

class ArtifactBoardScreen extends StatefulWidget {
  const ArtifactBoardScreen({super.key});

  @override
  State<ArtifactBoardScreen> createState() => _ArtifactBoardScreenState();
}

class _ArtifactBoardScreenState extends State<ArtifactBoardScreen> {
  bool _showDirectional = false;
  late TalkingMat talkingMat;
  late LinearBoard linearBoard;
  late GlobalKey<TalkingMatState> talkingMatKey;
  late GlobalKey<LinearBoardState> linearBoardKey;
  late LinearBoardController linearBoardController;
  int? _linearBoardFieldCount;

  @override
  void initState() {
    super.initState();
    // Initialize talkingMatKey and linearBoardKey
    talkingMatKey = GlobalKey<TalkingMatState>();
    linearBoardKey = GlobalKey<LinearBoardState>();

    // Synchronously initialize linearBoardController controller with an empty list and zero field count
    linearBoardController = LinearBoardController(
      artifacts: [],
      fieldCount: 0,
    );

    // Setup TalkingMat and LinearBoard
    talkingMat = TalkingMat(
      key: talkingMatKey,
      artifacts: [],
    );
    linearBoard = LinearBoard(
      key: linearBoardKey,
      linearBoardController: linearBoardController,
    );

    // Fetch and setup the linear board configuration
    _setupLinearBoardController();

    // Fetch current board status
    getCurrentBoardStatus();
  }

  /// Function for setting up the linear board
  void _setupLinearBoardController() async {
    // Get the count of fields from settings
    int? count = await SettingsService().linearArtifactCount() ?? 4;
    // If count is not current count, go ahead
    if (count != _linearBoardFieldCount) {
      setState(() {
        _linearBoardFieldCount = count;
        // Update the controller with new artifact list and field count
        linearBoardController.artifacts = List<BoardArtefact?>.filled(_linearBoardFieldCount!, null, growable: false);
        linearBoardController.fieldCount = _linearBoardFieldCount!;
      });
    }
  }

  /// Get the current status of whether the board is at talking mat or directional
  void getCurrentBoardStatus() async {
    // Get status from settings
    bool? showDirectionalBoard = await SettingsService().showDirectionalBoard();
    // If the bool is not null or not equal to current, go ahead
    if (showDirectionalBoard != null && showDirectionalBoard != _showDirectional) {
      _showDirectional = showDirectionalBoard;
    }
  }

  /// Switch the status of whether the board is at talking mat or directional
  void switchCurrentBoard() async {
    bool newStatus = !_showDirectional;
    // Update the setting with SettingsService
    await SettingsService().updateShowDirectionalBoard(newStatus);
    setState(() {
      _showDirectional = newStatus;
    });
  }

  /// Add an artifact to the currently active board
  void addArtifactToCurrentBoard(BoardArtefact artifact) {
    if (_showDirectional) {
      linearBoardController.addArtifact(artifact);
    } else {
      talkingMatKey.currentState?.addArtifact(artifact);
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = 5;
    double screenHeight = MediaQuery.of(context).size.height;
    double categoriesWidgetHeight = 60;
    double dividerHeight = 5;

    var categories = context.watch<ArtifactState>().categories;

    if (categories == null) {
      return Center(
        child: Text('Something went wrong with fetching the artifacts'),
      );
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Take minimum space needed
            mainAxisAlignment:
                MainAxisAlignment.start, // Align items to the start
            children: [
              SafeArea(
                bottom: false, // Don't add safe area padding at bottom
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
                          child: _showDirectional ? linearBoard : talkingMat,
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 30,
                        child: PopupMenuButton(
                            tooltip: "Brugerindstillinger",
                            offset: const Offset(0, 60),
                            icon: Icon(Icons.supervised_user_circle_outlined,
                                size: 50),
                            itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.settings, size: 20),
                                      title: const Text('Instillinger'),
                                      onTap: () {
                                        Navigator.of(context)
                                            .pushNamed('/settings');
                                      },
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.logout, size: 20),
                                      title: const Text('Log ud'),
                                      onTap: () {
                                        context.read<AuthState>().logout();
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                AuthPage.routeName,
                                                (route) => false);
                                      },
                                    ),
                                  ),
                                ]),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: RelationalBoardButton(
                            onPressed: () {
                              switchCurrentBoard();
                            },
                            icon: _showDirectional
                                ? const Icon(
                              IconData(0xf685, fontFamily: 'MaterialIcons'),
                              size: 24.0,
                            )
                                : const Icon(
                              IconData(0xf601, fontFamily: 'MaterialIcons'),
                              size: 24.0,
                            ),
                          ),
                        ),
                      ),
                      const QuickChatButton(),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Colors.transparent,
                height: dividerHeight,
              ),
              Padding(
                  padding: EdgeInsets.only(left: padding, right: padding),
                  child: SizedBox(
                      height: categoriesWidgetHeight,
                      child: categories_widget.CategoriesWidget(
                        // Use the aliased widget here
                        categories: categories,
                        widgetHeight: categoriesWidgetHeight,
                        onArtifactAdded: addArtifactToCurrentBoard,
                      )))
            ],
          ),
        ),
      ),
    );
  }
}
