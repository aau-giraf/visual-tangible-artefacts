import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/ui/screens/take_picture_screen.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:vta_app/src/ui/widgets/board/add_item_popup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vta_app/src/ui/widgets/categories/addPicture.dart';
import 'package:vta_app/src/ui/widgets/categories/categories_edit.dart';
import 'package:vta_app/src/ui/widgets/utilities/custom_delay_drag_listener.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'package:http/http.dart' as http;

class CategoriesWidget extends StatefulWidget {
  final double widgetHeight;
  final ArtefactController artefactController;
  final Function(BoardArtefact) onArtifactAdded;

  const CategoriesWidget({
    super.key,
    required this.widgetHeight,
    required this.artefactController,
    required this.onArtifactAdded,
  });

  @override
  State<StatefulWidget> createState() => _CategoriesWidgetState();
}

class _CategoriesWidgetState extends State<CategoriesWidget> {
  late List<Category> categories;
  late ArtifactState artifactState;
  late AuthState authState;
  bool moveCategoriesMode = false;

  @override
  void initState() {
    super.initState();
    // Initialize states
    authState = Provider.of<AuthState>(context, listen: false);
    artifactState = Provider.of<ArtifactState>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.artefactController.updateMostUsedCategories(context: context);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update states when dependencies change
    authState = Provider.of<AuthState>(context, listen: false);
    artifactState = Provider.of<ArtifactState>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    // Get latest state in build method
    authState = Provider.of<AuthState>(context, listen: false);
    artifactState = Provider.of<ArtifactState>(context, listen: false);

    return TapRegion(
        onTapOutside: (event) => {
              if (moveCategoriesMode)
                {
                  setState(() {
                    moveCategoriesMode = false;
                  })
                }
            },
        child: _buildCategoryList());
  }

  Widget _buildCategoryList() {
    return Theme(
      data: ThemeData(
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Consumer<AuthState>(
        builder: (context, auth, _) {
          return ListenableBuilder(
            listenable: widget.artefactController,
            builder: (context, child) {
              categories = widget.artefactController.categories ?? [];
              List<Category> mostUsedCategories =
                  widget.artefactController.mostUsedCategories ?? [];
              List<Category> regularCategories = categories;

              return _buildCategoriesWithMostUsed(
                  mostUsedCategories, regularCategories, auth);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoriesWithMostUsed(List<Category> mostUsedCategories,
      List<Category> regularCategories, AuthState auth) {
    List<Widget> items = [];

    for (int i = 0; i < mostUsedCategories.length; i++) {
      items.add(_buildMostUsedCategoryItem(mostUsedCategories[i], i));
    }
    if (mostUsedCategories.isNotEmpty &&
        (regularCategories.isNotEmpty || true)) {
      items.add(_buildSeparator());
    }

    for (int i = 0; i < regularCategories.length; i++) {
      if (moveCategoriesMode) {
        items.add(Material(
          key: ValueKey('regular_${regularCategories[i].categoryId}'),
          elevation: 2,
          child: _buildRegularCategoryItem(regularCategories[i], i),
        ));
      } else {
        items.add(_buildRegularCategoryItem(regularCategories[i], i,
            key: ValueKey('regular_${regularCategories[i].categoryId}')));
      }
    }

    items.add(_buildAddCategoryButton(key: ValueKey('add_button')));

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: items[index],
        );
      },
    );
  }

  Widget _buildAddCategoryButton({Key? key}) {
    return SizedBox(
      key: key,
      height: widget.widgetHeight,
      width: widget.widgetHeight * 2,
      child: TextButton(
        onPressed: () {
          widget.artefactController.newCategory(context);
        },
        child: _buildAddCategoryContainer(),
      ),
    );
  }

  Container _buildAddCategoryContainer() {
    return Container(
      height: widget.widgetHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.add_circle,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryContainer(Category item) {
    var headers = <String, String>{
      'Authorization': 'Bearer ${GetIt.instance.get<Token>().value}'
    };

    return Container(
      height: widget.widgetHeight,
      width: widget.widgetHeight * 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          // Added Center widget
          child: item.imageUrl != null
              ? Image.network(
                  item.imageUrl!,
                  headers: headers,
                  fit: BoxFit.contain,
                )
              : Text(item.name!),
        ),
      ),
    );
  }

  Widget _buildMostUsedCategoryItem(Category item, int index) {
    return Container(
      child: GestureDetector(
        onLongPress: () {
          _showCategoryEditModal(context, item);
        },
        child: TextButton(
          onPressed: () {
            widget.artefactController
                .trackCategoryUsage(item.categoryId!, context: context);
            _showCategoryModal(context, item);
          },
          child: _buildCategoryContainer(item),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 4,
      height: widget.widgetHeight,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Container(
          width: 2,
          height: widget.widgetHeight * 0.6,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 214, 11, 11),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildRegularCategoryItem(Category item, int index, {Key? key}) {
    if (moveCategoriesMode) {
      return CustomDelayDragStartListener(
        delay: 200,
        key: key,
        index: index,
        child: _buildRegularCategoryButton(key, context, item),
      );
    } else {
      return GestureDetector(
        key: key,
        onLongPress: () {
          _showCategoryEditModal(context, item);
        },
        child: _buildRegularCategoryButton(key, context, item),
      );
    }
  }

  TextButton _buildRegularCategoryButton(
      Key? key, BuildContext context, Category item) {
    return TextButton(
      key: key,
      onPressed: () {
        widget.artefactController
            .trackCategoryUsage(item.categoryId!, context: context);
        _showCategoryModal(context, item);
      },
      child: _buildCategoryContainer(item),
    );
  }

//ModalSheet for viewing categories with artefacts
  void _showCategoryModal(BuildContext context, Category category) {
    setState(() {
      showModalBottomSheet(
        backgroundColor: Colors.white,
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
    });
  }

// ModalSheet for editing and deleting categories
  void _showCategoryEditModal(BuildContext context, Category category) {
    final categoriesEdit = CategoriesEdit(
      categoryName: category.name!,
      imageUrl: category.imageUrl,
      categoryId: category.categoryId!,
      onEdit: () {
        MaterialPageRoute(builder: (context) => AddPicturePage());
      }, // Pass edit functionality if needed
    );
    showModalBottomSheet(
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit', style: TextStyle(color: Colors.blue)),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  _showEditCategoryPopup(context, category);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  widget.artefactController.deleteCategory(category, context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_down, color: Colors.green),
                title:
                    const Text('Move', style: TextStyle(color: Colors.green)),
                onTap: () {
                  setState(() {
                    moveCategoriesMode = true;
                    Navigator.pop(context); // Close the modal
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the modal
                },
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageGrid(Category category) {
    bool isInDeletionMode = false;

    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      int totalItems = (category.artefacts?.length ?? 0) + 1;

      return GestureDetector(
        onTap: () {
          if (isInDeletionMode) {
            setState(() {
              isInDeletionMode = false;
            });
          }
        },
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  // Responsive grid: 3 columns on mobile, 4 on tablet, 8 on desktop
                  final crossAxisCount = screenWidth < 600 
                      ? 3 
                      : screenWidth < 900 
                          ? 4 
                          : 8;
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddArtifactButton(category);
                  } else {
                    final artifactIndex = index - 1;
                    if (artifactIndex >= category.artefacts!.length) {
                      return SizedBox();
                    }
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          isInDeletionMode = true;
                        });
                      },
                      child: _buildImageGridItem(
                        context,
                        artifactIndex,
                        category,
                        isInDeletionMode,
                        () => setState(() {
                          isInDeletionMode = true;
                        }),
                        onDelete: () {
                          setState(() {});
                        },
                      ),
                    );
                  }
                },
                );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildImageGridItem(BuildContext context, int index, Category category,
      bool isInDeletionMode, VoidCallback onLongPress,
      {required VoidCallback onDelete}) {
    var authState = Provider.of<AuthState>(context);
    var artifactState = Provider.of<ArtifactState>(context, listen: false);
    var headers = <String, String>{
      'Authorization': 'Bearer ${GetIt.instance.get<Token>().value}'
    };

    if (index >= category.artefacts!.length) {
      return SizedBox(); // Safety check
    }

    var boardArtefacts = category.artefacts!
        .map((artefact) =>
            BoardArtefact.fromArtefact(artefact, headers: headers))
        .toList();

    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TextButton(
              onPressed: isInDeletionMode
                  ? null
                  : () {
                      widget.onArtifactAdded(boardArtefacts[index]);
                      Navigator.pop(context);
                    },
              child: boardArtefacts[index].content,
            ),
          ),
          if (isInDeletionMode)
            Positioned(
              right: -10,
              top: -10,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () async {
                    await widget.artefactController
                        .deleteArtefact(context, category.artefacts![index]);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddArtifactButton(Category category) {
    return TextButton(
      onPressed: () {
        widget.artefactController.newArtifact(context, category.categoryId!);
        // _showAddArtifactPopup(context, category);
      },
      child: Icon(
        Icons.add_circle,
        size: 50,
      ),
    );
  }

  void _showAddCategoryPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddItemPopup(
          isCategory: true,
          title: 'Tilføj kategori',
          onSubmit: (name, imageBytes, soundBytes) {
            var artifactState =
                Provider.of<ArtifactState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var newCategory = Category(
                name: name,
                userId: authState.userId,
                categoryIndex: 0,
                image: imageBytes);
            artifactState.addCategory(newCategory, token: authState.token!);
          },
        );
      },
    );
  }

  void _showEditCategoryPopup(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddItemPopup(
          isCategory: true,
          title: 'Rediger kategori',
          category: category,
          onSubmit: (name, imageBytes, soundBytes) {
            var artifactState =
                Provider.of<ArtifactState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var newCategory = Category(
                categoryId: category.categoryId,
                name: name,
                userId: authState.userId,
                categoryIndex: category.categoryIndex,
                image: imageBytes);
            artifactState.updateCategory(newCategory,
                token: authState.token!);
          },
        );
      },
    );
  }

  void _showAddArtifactPopup(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddItemPopup(
          isCategory: false,
          onSubmit: (name, bytes, sound) async {
            var artifactState =
                Provider.of<ArtifactState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var newArtifact = Artefact(
                categoryId: category.categoryId,
                userId: authState.userId,
                image: bytes,
                sound: sound);
            await artifactState.addArtifact(newArtifact,
                token: authState.token!);
          },
          title: "Tilføj Artifakt",
        );
      },
    );
  }
}

