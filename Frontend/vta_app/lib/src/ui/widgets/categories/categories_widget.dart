import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';

class CategoriesWidget extends StatefulWidget {
  final List<Category> categories;
  final double widgetHeight;
  final Function(bool isMatrixVisible) isMatrixVisible;
  final GlobalKey<TalkingMatState> talkingMatKey;

  const CategoriesWidget({
    super.key,
    required this.categories,
    required this.widgetHeight,
    required this.isMatrixVisible,
    required this.talkingMatKey,
  });

  @override
  State<StatefulWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  bool _isMatrixVisible = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(10),
          right: Radius.circular(10),
        ),
        child: _buildCategoryList(),
      ),
    );
  }

  Widget _buildCategoryList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: widget.categories.length + 1, //+1 room for add button
      itemBuilder: (context, index) {
        if (index == widget.categories.length) {
          return _buildAddCategoryButton();
        }
        return _buildCategoryItem(context, index);
      },
      separatorBuilder: (context, index) => const SizedBox(width: 10),
    );
  }

  TextButton _buildAddCategoryButton() {
    return TextButton(
      onPressed: () {
        _showAddCategoryPopup(context);
      },
      child: _buildAddCategoryContainer(),
    );
  }

  Container _buildAddCategoryContainer() {
    return Container(
      height: widget.widgetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const SizedBox(width: 5),
            Icon(
              Icons.add_circle,
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, int index) {
    final item = widget.categories[index];
    return TextButton(
      onPressed: () => _showCategoryModal(context, widget.categories[index]),
      child: _buildCategoryContainer(item),
    );
  }

  Widget _buildCategoryContainer(Category item) {
    return Container(
      height: widget.widgetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Text(item.name!),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  void _showCategoryModal(BuildContext context, Category category) {
    setState(() {
      showModalBottomSheet(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: FractionallySizedBox(
              heightFactor: 0.8,
              child: _buildImageGrid(category),
            ),
          );
        },
      );
      widget.isMatrixVisible(!_isMatrixVisible);
      _isMatrixVisible = !_isMatrixVisible;
    });
  }

  Widget _buildImageGrid(Category category) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: category.artefacts!.length,
      itemBuilder: (context, index) =>
          _buildImageGridItem(context, index, category),
    );
  }

  Widget _buildImageGridItem(
      BuildContext context, int index, Category category) {
    var authState = Provider.of<AuthState>(context);
    var headers = <String, String>{
      'Authorization': 'Bearer ${authState.token}'
    };
    var boardArtefacts = category.artefacts!
        .map((artefact) =>
            BoardArtefact.fromArtefact(artefact, headers: headers))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: TextButton(
          onPressed: () => {
                widget.talkingMatKey.currentState
                    ?.addArtifact(boardArtefacts[index]),
                Navigator.pop(context),
              },
          child: boardArtefacts[index].content),
    );
  }

  void _showAddCategoryPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: 741,
            height: 470,
            decoration: BoxDecoration(
              color: Color(0xFFF5F2E7),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 4,
                  offset: Offset(4, 4),
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18.0),
                    child: Text(
                      'Tilføj kategori',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 32,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: 741 / 2,
                    child: TextField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Kategori navn',
                        hintStyle: TextStyle(color: Color(0xFF7C7C7C)),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildButton('Tag nyt billede',
                            'assets/images/camera_icon_filled.png'),
                        _buildButton('Upload', 'assets/images/folder_icon.png'),
                        _buildButton('Lav med AI', 'assets/images/ai_file.png'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFBADFB5)),
                        onPressed: () {
                          // Close the dialog
                        },
                        child: Text(
                          'Tilføj',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 188,
          height: 185,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageUrl),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
