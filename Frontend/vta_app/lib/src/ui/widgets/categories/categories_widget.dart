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
      itemCount: widget.categories.length,
      itemBuilder: _buildCategoryItem,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
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
}
