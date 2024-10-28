@override
  Widget build(BuildContext context) {
    double padding = 10;
    double screenHeight = MediaQuery.of(context).size.height;
    double categoriesWidgetHeight = 120;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: ExactAssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
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
                    MediaQuery.of(context).padding.top - dividerHeight,
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Center(
                        child: _showDirectional ? linearBoard : talkingMat,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Artifact newArtifact = Artifact(
                          content:
                              SvgPicture.asset('assets/icons/sillyface.svg'),
                          position: const Offset(299, 200),
                        );
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
            ),
            Divider(
              color: Colors.transparent,
              height: dividerHeight,
            ),
            Padding(
                padding: EdgeInsets.only(left: padding, right: padding),
                child: SizedBox(
                    height: categoriesWidgetHeight,
                    child: CategoriesWidget(
                      categories: categories,
                      widgetHeight: categoriesWidgetHeight,
                      talkingMatKey: talkingMatKey,
                      isMatrixVisible: (bool isVisible) {},
                    )))
          ],
        ),
      ),
    );
  }
}
