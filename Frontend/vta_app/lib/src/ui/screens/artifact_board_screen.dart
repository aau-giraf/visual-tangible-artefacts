import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:vta_app/src/models/user.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import '../widgets/board/relational_board_button.dart';
import '../widgets/board/linear_board.dart';
import '../widgets/board/quickchat.dart';
import '../widgets/categories/categories_widget.dart';
import '../widgets/categories/category.dart';

class ArtifactBoardScreen extends StatefulWidget {
  const ArtifactBoardScreen({super.key});

  @override
  State<ArtifactBoardScreen> createState() => _ArtifactBoardScreenState();
}

class _ArtifactBoardScreenState extends State<ArtifactBoardScreen> {
  bool _showDirectional = false;
  late TalkingMat talkingMat;
  late GlobalKey<TalkingMatState> talkingMatKey;
  late LinearBoard linearBoard;
  List<Category> categories = [
    Category(
        id: "Category 1",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 2",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 3",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 4",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 5",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 6",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 7",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
    Category(
        id: "Category 8",
        imageLink:
            "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg"),
  ];
  List<String> imageMatrix = [
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
    "https://st3.depositphotos.com/2212674/16303/i/450/depositphotos_163039262-stock-photo-outraged-woman-asking-what-the.jpg",
  ];

  @override
  void initState() {
    super.initState();
    talkingMatKey = GlobalKey<TalkingMatState>();
    talkingMat = TalkingMat(
      key: talkingMatKey,
      artifacts: [],
    );
    linearBoard = LinearBoard();
  }

  @override
  Widget build(BuildContext context) {
    double padding = 10; // Padding around the ArtifactBoard
    double screenHeight = MediaQuery.of(context).size.height;
    double categoriesWidgetHeight = 120; // Height of the bottom navigation bar
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: screenHeight - categoriesWidgetHeight,
              child: Stack(
                children: [
                  // Center the ArtifactBoard with appropriate padding
                  Padding(
                    padding: EdgeInsets.only(
                        top: padding, left: padding, right: padding, bottom: 0),
                    child: Center(
                      child: _showDirectional ? linearBoard : talkingMat,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Create a new artifact and add it
                      Artifact newArtifact = Artifact(
                        content: SvgPicture.asset('assets/icons/sillyface.svg'),
                        position: const Offset(299, 200),
                      );
                      // Call the addArtifact method directly
                      talkingMatKey.currentState?.addArtifact(newArtifact);
                    },
                    child: const Text('Add Artifact'),
                  ),
                  Positioned(
                    top: 30,
                    left: 30,
                    child: RelationalBoardButton(
                      onPressed: () {
                        setState(() {
                          _showDirectional = !_showDirectional;
                        });
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
                  const QuickChatButton(),
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.only(left: padding, right: padding),
                child: SizedBox(
                    height: categoriesWidgetHeight,
                    child: CategoriesWidget(
                      categories: categories,
                      imageMatrix: imageMatrix,
                      widgetHeight: categoriesWidgetHeight,
                      isMatrixVisible: (bool isVisible) {},
                    )))
          ],
        ),
      ),
    );
  }
}
