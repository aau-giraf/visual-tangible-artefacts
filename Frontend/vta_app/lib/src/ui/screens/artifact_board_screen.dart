import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/board/quick_add_artefact.dart';
import '../widgets/categories/categories_widget.dart'
    as categories_widget; // Aliased import
import 'package:vta_app/src/modelsDTOs/user.dart' as user_model;
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';

import 'package:vta_app/src/ui/screens/boards_view.dart';
import 'package:vta_app/src/ui/screens/teachers_hub_panel.dart';
import 'package:vta_app/src/ui/widgets/board/board_bar.dart';
import 'package:logging/logging.dart';

final _log = Logger('ArtifactBoardScreen');

class ArtifactBoardScreen extends StatefulWidget {
  const ArtifactBoardScreen({
    super.key,
    required this.artifactController,
    required this.authController,
    required this.settingsController,
  });
  static const String routeName = "/boardview";

  final ArtefactController artifactController;
  final AuthController authController;
  final SettingsController settingsController;

  @override
  State<ArtifactBoardScreen> createState() => _ArtifactBoardScreenState();
}

class _ArtifactBoardScreenState extends State<ArtifactBoardScreen> {
  List<Category>? categories;
  static const String _controllerKey = 'ArtifactBoardController';

  bool _hubOpen = false;
  bool _boardsOpen = false;

  void _closeHub() {
    setState(() {
      _hubOpen = false;
      _boardsOpen = false;
    });
  }

  void _notifyView() {
    if (mounted) {
      _log.fine(
          '[ArtifactBoardScreen] notifyView callback - calling setState');
      setState(() {});
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
        ),
      );
    }
  }

  ArtifactBoardController get controller {
    // Use GetIt to store controller persistently across widget recreations
    try {
      final existingController = GetIt.instance.get<ArtifactBoardController>(
        instanceName: _controllerKey,
      );
      _log.fine(
          '[ArtifactBoardScreen] get controller - Reusing existing controller from GetIt: ${existingController.hashCode}');
      // Update the notifyView callback to point to current widget state
      existingController.updateNotifyView(_notifyView);
      // Update the showMessage callback to point to current widget state
      existingController.updateShowMessage(_showMessage);
      return existingController;
    } catch (e) {
      // Controller doesn't exist yet, create and register it
      _log.fine(
          '[ArtifactBoardScreen] get controller - Creating NEW ArtifactBoardController and registering in GetIt');
      final newController = ArtifactBoardController(
        notifyView: _notifyView,
        settingsController: widget.settingsController,
      );
      // Set the showMessage callback
      newController.updateShowMessage(_showMessage);
      GetIt.instance.registerSingleton<ArtifactBoardController>(
        newController,
        instanceName: _controllerKey,
      );
      return newController;
    }
  }

  user_model.User? currentUser;
  late Future<user_model.User?> userFuture;

  @override
  void initState() {
    super.initState();
    _log.fine('[ArtifactBoardScreen] initState - Initializing state');
    // Controller will be lazily initialized on first access via GetIt
    // This ensures it persists across widget recreations
    // Load user data as a future that will be awaited
    userFuture = _loadCurrentUser();
  }

  @override
  void dispose() {
    _log.fine(
        '[ArtifactBoardScreen] dispose - Disposing state (controller persists in GetIt)');
    // DON'T remove controller from GetIt - it should persist across widget recreations
    // Only remove it when truly leaving the screen (e.g., in a route guard)
    super.dispose();
  }

  Future<user_model.User?> _loadCurrentUser() async {
    final user = await widget.authController.getCurrentUser();
    _log.fine('Loaded user: ${user?.username}, role: ${user?.role}');
    if (mounted) {
      setState(() {
        currentUser = user;
      });
    }
    return user;
  }


  @override
  Widget build(BuildContext context) {
    var artifactController = widget.artifactController;
    categories = artifactController.categories;

    if (categories == null) {
      return FutureBuilder(
        future: artifactController.updateArtifacts(context: context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show loading spinner while waiting
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (artifactController.categories == null) {
              categories = [];
            }
            return _buildPage(context);
          }
          return SizedBox.shrink(); // Fallback widget
        },
      );
    }
    return _buildPage(context);
  }

        Scaffold _buildPage(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double safeTop = MediaQuery.of(context).padding.top;
    double padding = screenWidth > 600 ? 5 : 2;
    double categoriesWidgetHeight = screenWidth > 600 ? 90 : 80;
    double dividerHeight = screenWidth > 600 ? 10 : 5;
    var artifactController = widget.artifactController;
    categories = artifactController.categories;

    // Height of the board area (same math as the container below)
    double boardAreaHeight =
        screenHeight - categoriesWidgetHeight - safeTop - dividerHeight;

    // Panel geometry: tweak these to line up with the board box
    double panelWidth = (screenWidth * 0.32).clamp(200.0, 320.0);
    double boxLeft = padding * 2; // container padding + board padding
    double boxMarginY = 5; // gap between board area edge and the box
    double boxRadius = 20; // corner radius of the box
    double panelTop = safeTop + boxMarginY;
    double panelHeight = boardAreaHeight - boxMarginY * 2;

    // Boards view fills the rest of the box to the right of the panel
    double boardsLeft = boxLeft + panelWidth;
    double boardsWidth = screenWidth - boxLeft * 2 - panelWidth;

    return Scaffold(
      body: Stack(
        children: [
          // Main content (unchanged, minus the panel and burger)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SafeArea(
                      bottom: false,
                      child: Container(
                        height: boardAreaHeight,
                        padding: EdgeInsets.symmetric(horizontal: padding),
                        child: Stack(
                          children: [
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: padding),
                              child: Center(
                                child: controller.showDirectional
                                    ? LinearBoard(
                                        key: controller.linearBoardKey,
                                        linearBoardController:
                                            controller.linearBoardController,
                                      )
                                    : TalkingMat(
                                        key: controller.talkingMatKey,
                                        artifacts: [],
                                        controller:
                                            controller.talkingmatController,
                                      ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(
                                    left: screenWidth > 600 ? 20 : 10),
                                child: RelationalBoardButton(
                                  onPressed: () {
                                    controller.switchCurrentBoard();
                                  },
                                  icon: controller.showDirectional
                                      ? Icon(
                                          IconData(0xf685,
                                              fontFamily: 'MaterialIcons'),
                                          size: screenWidth > 600 ? 24.0 : 20.0,
                                        )
                                      : Icon(
                                          IconData(0xf601,
                                              fontFamily: 'MaterialIcons'),
                                          size: screenWidth > 600 ? 24.0 : 20.0,
                                        ),
                                ),
                              ),
                            ),
                            QuickAddArtefactButton(
                                artefactController: artifactController,
                                onArtifactAdded:
                                    controller.addArtifactToCurrentBoard),
                            const QuickChatButton(),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: const Color.fromARGB(0, 0, 0, 0),
                      height: dividerHeight,
                    ),
                    Padding(
                        padding:
                            EdgeInsets.only(left: padding, right: padding),
                        child: SizedBox(
                            height: categoriesWidgetHeight,
                            child: BoardBar(
                              widgetHeight: categoriesWidgetHeight,
                              controller: controller,
                            ),))
                  ],
                ),
              ),
            ),
          ),

          // Gray scrim over the whole app; tap to close
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_hubOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _hubOpen ? 1 : 0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeHub,
                  child: Container(color: Colors.black45),
                ),
              ),
            ),
          ),

          // Side panel
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: panelTop,
            height: panelHeight,
            width: panelWidth,
            // extra 40 keeps the shadow off-screen while closed
            left: _hubOpen ? boxLeft : -panelWidth - 40,
            child: IgnorePointer(
              ignoring: !_hubOpen,
              child: TeachersHubPanel(
                isOpen: _hubOpen,
                selectedTab: _boardsOpen ? HubTab.boards : null,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(boxRadius),
                ),
                onBoards: () => setState(() => _boardsOpen = true),
                onSettings: () {
                  _closeHub();
                  Navigator.of(context).pushNamed('/settings');
                },
                onLogout: () {
                  _closeHub();
                  widget.authController.logout(context);
                },
              ),
            ),
          ),

          // Burger tab
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            top: panelTop,
            left: _hubOpen ? boxLeft + panelWidth : boxLeft,
            child: Material(
              color: Colors.white,
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(_hubOpen ? 0 : boxRadius),
                bottomRight: const Radius.circular(12),
              ),
              child: IconButton(
                tooltip: 'Lærer Hub',
                iconSize: screenWidth > 600 ? 35 : 28,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () =>
                    _hubOpen ? _closeHub() : setState(() => _hubOpen = true),
              ),
            ),
          ),

          // Boards
          Positioned(
            top: panelTop,
            height: panelHeight,
            left: boardsLeft,
            width: boardsWidth,
            child: IgnorePointer(
              ignoring: !_boardsOpen,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _boardsOpen ? 1 : 0,
                child: BoardsView(
                  isOpen: _boardsOpen,
                  controller: controller,
                  onClose: _closeHub,
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(boxRadius),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  }