import 'package:flutter/material.dart';
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
  late ArtifactBoardController controller;
  List<Category>? categories;
  user_model.User? currentUser;
  late Future<user_model.User?> userFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with a callback to setState
    controller = ArtifactBoardController(
        notifyView: () {
      setState(() {});
    }, settingsController: widget.settingsController);
    // Load user data as a future that will be awaited
    userFuture = _loadCurrentUser();
  }

  Future<user_model.User?> _loadCurrentUser() async {
    final user = await widget.authController.getCurrentUser();
    debugPrint('Loaded user: ${user?.username}, role: ${user?.role}');
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
    double padding = 5;
    double screenHeight = MediaQuery.of(context).size.height;
    double categoriesWidgetHeight = 60;
    double dividerHeight = 5;
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
                              ? controller.linearBoard!
                              : controller.talkingMat!,
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
                            itemBuilder: (context) {
                              List<PopupMenuItem> items = [];


                              debugPrint('Building menu - currentUser: ${currentUser?.username}, role: ${currentUser?.role}');
                              debugPrint('Is caregiver? ${currentUser?.role == user_model.UserRole.caregiver}');

                              // Only show "Start Opkald" for caregivers
                              if (currentUser?.role == user_model.UserRole.caregiver) {
                                items.add(
                                  PopupMenuItem(
                                    child: ListTile(
                                      leading: Icon(Icons.call, size: 20),
                                      title: const Text('Start Opkald'),
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
                                  child: ListTile(
                                    leading: Icon(Icons.settings, size: 20),
                                    title: const Text('Indstillinger'),
                                    onTap: () {
                                      Navigator.of(context).pop();
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
                          padding: EdgeInsets.only(left: 20),
                          child: RelationalBoardButton(
                            onPressed: () {
                              controller.switchCurrentBoard();
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
                color: Colors.transparent,
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
