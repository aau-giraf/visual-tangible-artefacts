import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/controllers/auth_controller.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/board/quick_add_artefact.dart';
import 'package:vta_app/src/ui/screens/remote_session_screen.dart';
import '../widgets/categories/categories_widget.dart'
    as categories_widget; // Aliased import
import 'package:vta_app/src/modelsDTOs/user.dart' as user_model;
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/ui/widgets/board/linear_board.dart';

import 'package:vta_app/src/ui/widgets/board/board_switcher.dart';
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
    double padding = screenWidth > 600 ? 5 : 2;
    double categoriesWidgetHeight = screenWidth > 600 ? 90 : 80;
    double dividerHeight = screenWidth > 600 ? 10 : 5;
    var artifactController = widget.artifactController;
    categories = artifactController.categories;

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
                          child: controller.showDirectional
                              ? LinearBoard(
                                  key: controller.linearBoardKey,
                                  linearBoardController:
                                      controller.linearBoardController,
                                )
                              : TalkingMat(
                                  key: controller.talkingMatKey,
                                  artifacts: [],
                                  controller: controller.talkingmatController,
                                ),
                        ),
                      ),
                      Positioned(
                        top: screenWidth > 600 ? 10 : 10,
                        left: screenWidth > 600 ? 15 : 10,
                        child: PopupMenuButton(
                            tooltip: "Brugerindstillinger",
                            offset: Offset(0, screenWidth > 600 ? 60 : 40),
                            icon: Icon(Icons.supervised_user_circle_outlined,
                                size: screenWidth > 600 ? 50 : 35),
                            iconSize: screenWidth > 600
                                ? 50
                                : 35, // ensures shadow matches icon
                            padding: EdgeInsets
                                .zero, // removes extra padding around the icon
                            itemBuilder: (context) {
                              List<PopupMenuItem> items = [];

                              _log.fine(
                                  'Building menu - currentUser: ${currentUser?.username}, role: ${currentUser?.role}');
                              _log.fine(
                                  'Is caregiver? ${currentUser?.role == user_model.UserRole.caregiver}');

                              items.add(
                                PopupMenuItem(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(Icons.dashboard,
                                        size: screenWidth > 600 ? 20 : 16),
                                    title: Text(
                                        'Tavler (${controller.activeBoard.title})',
                                        style: TextStyle(
                                            fontSize:
                                                screenWidth > 600 ? 16 : 14)),
                                    onTap: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20)),
                                        ),
                                        builder: (context) =>
                                            DraggableScrollableSheet(
                                          initialChildSize: 0.6,
                                          minChildSize: 0.4,
                                          maxChildSize: 0.9,
                                          expand: false,
                                          builder:
                                              (context, scrollController) =>
                                                  BoardSelectionSheet(
                                            controller: controller,
                                            scrollController: scrollController,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );

                              // Only for caregivers
                              if (currentUser?.role ==
                                  user_model.UserRole.caregiver) {
                                items.add(
                                  PopupMenuItem(
                                    padding: EdgeInsets.zero,
                                    child: ListTile(
                                      leading: Icon(Icons.call,
                                          size: screenWidth > 600 ? 20 : 16),
                                      title: Text('Start Opkald',
                                          style: TextStyle(
                                              fontSize:
                                                  screenWidth > 600 ? 16 : 14)),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        SignalRService()
                                            .setOwnerBoardController(
                                                controller);
                                        Navigator.of(context).pushNamed(
                                            RemoteSessionScreen.routeName);
                                      },
                                    ),
                                  ),
                                );
                              }

                              items.addAll([
                                PopupMenuItem(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(Icons.settings,
                                        size: screenWidth > 600 ? 20 : 16),
                                    title: Text('Indstillinger',
                                        style: TextStyle(
                                            fontSize:
                                                screenWidth > 600 ? 16 : 14)),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context)
                                          .pushNamed('/settings');
                                    },
                                  ),
                                ),
                                PopupMenuItem(
                                  padding: EdgeInsets.zero,
                                  child: ListTile(
                                    leading: Icon(Icons.logout,
                                        size: screenWidth > 600 ? 20 : 16),
                                    title: Text('Log ud',
                                        style: TextStyle(
                                            fontSize:
                                                screenWidth > 600 ? 16 : 14)),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      widget.authController.logout(context);
                                    },
                                  ),
                                ),
                              ]);

                              return items;
                            }),
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
                  padding: EdgeInsets.only(left: padding, right: padding),
                  child: SizedBox(
                      height: categoriesWidgetHeight,
                      child: categories_widget.CategoriesWidget(
                        // Use the aliased widget here
                        widgetHeight: categoriesWidgetHeight,
                        onArtifactAdded: controller.addArtifactToCurrentBoard,
                        artefactController: artifactController,
                      )))
            ],
          ),
        ),
      ),
    );
  }
}
