import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/functions/auth.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import '../widgets/board/relational_board_button.dart';
// import '../widgets/board/linear_board.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/categories/categories_widget.dart'
    as categories_widget; // Aliased import

class ArtifactBoardScreen extends StatefulWidget {
  const ArtifactBoardScreen({super.key});
  static const String routeName = "/boardview";

  @override
  State<ArtifactBoardScreen> createState() => _ArtifactBoardScreenState();
}

class _ArtifactBoardScreenState extends State<ArtifactBoardScreen> {
  bool _showDirectional = false;
  late TalkingMat talkingMat;
  late GlobalKey<TalkingMatState> talkingMatKey;
  // late LinearBoard linearBoard;

  @override
  void initState() {
    super.initState();
    talkingMatKey = GlobalKey<TalkingMatState>();
    talkingMat = TalkingMat(
      key: talkingMatKey,
      artifacts: [],
    );
    // linearBoard = LinearBoard();
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
                          child: /*_showDirectional ? linearBoard :*/
                              talkingMat,
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
                      // Positioned(
                      //   top: 30,
                      //   left: 30,
                      //   child: RelationalBoardButton(
                      //     onPressed: () {
                      //       setState(() {
                      //         _showDirectional = !_showDirectional;
                      //       });
                      //     },
                      //     icon: _showDirectional
                      //         ? const Icon(
                      //             IconData(0xf685, fontFamily: 'MaterialIcons'),
                      //             size: 24.0,
                      //           )
                      //         : const Icon(
                      //             IconData(0xf601, fontFamily: 'MaterialIcons'),
                      //             size: 24.0,
                      //           ),
                      //   ),
                      // ),
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
                        talkingMatKey: talkingMatKey,
                      )))
            ],
          ),
        ),
      ),
    );
  }
}
