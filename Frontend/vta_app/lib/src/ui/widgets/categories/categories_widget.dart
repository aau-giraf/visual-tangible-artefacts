import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/models/artefact.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/notifiers/vta_notifiers.dart';
import 'package:vta_app/src/ui/screens/take_picture_screen.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vta_app/src/ui/widgets/categories/addPicture.dart';
import 'package:vta_app/src/ui/widgets/categories/categories_edit.dart';
import 'package:cross_file/cross_file.dart';
import 'package:vta_app/src/ui/widgets/utilities/custom_delay_drag_listener.dart';
import 'package:vta_app/src/utilities/services/camera_service.dart';
import 'package:http/http.dart' as http;

class CategoriesWidget extends StatefulWidget {
  final List<Category> categories;
  final double widgetHeight;
  final Function(BoardArtefact) onArtifactAdded;

  const CategoriesWidget({
    super.key,
    required this.categories,
    required this.widgetHeight,
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
    artifactState = Provider.of<ArtifactState>(context, listen: false);
    authState = Provider.of<AuthState>(context, listen: false);
    categories = widget.categories;
  }

  @override
  Widget build(BuildContext context) {
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
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        buildDefaultDragHandles: false,
        itemCount: categories.length + 1, //+1 room for add button
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _buildAddCategoryButton(key: ValueKey('add_button'));
          }
          if (moveCategoriesMode) {
            return Material(
              key: ValueKey(categories[index].categoryId),
              elevation: 2,
              child: _buildCategoryItem(context, index),
            );
          }
          return _buildCategoryItem(context, index,
              key: ValueKey(categories[index].categoryId));
        },
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            newIndex = min(newIndex, categories.length - 1);

            final Category movedCategory = categories.removeAt(oldIndex);
            categories.insert(newIndex, movedCategory);

            for (int i = min(oldIndex, newIndex);
                i <= max(oldIndex, newIndex);
                i++) {
              categories[i].categoryIndex = i;
              categories[i].userId = authState.userId;
              artifactState.updateCategory(
                categories[i],
                token: authState.token!,
              );
            }
          });
        },
      ),
    );
  }

  Widget _buildAddCategoryButton({Key? key}) {
    return SizedBox(
      key: key,
      height: widget.widgetHeight,
      width: widget.widgetHeight * 2,
      child: TextButton(
        onPressed: () {
          _showAddCategoryPopup(context);
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

  Widget _buildCategoryItem(BuildContext context, int index, {Key? key}) {
    final item = categories[index];
    if (moveCategoriesMode) {
      return CustomDelayDragStartListener(
        delay: 200,
        key: key,
        index: index,
        child: _buildCategoryButton(key, context, index, item),
      );
    } else {
      return GestureDetector(
        key: key,
        onLongPress: () {
          _showCategoryEditModal(context, item); // Show modal on long press
        },
        child: _buildCategoryButton(key, context, index, item),
      );
    }
  }

  TextButton _buildCategoryButton(
      Key? key, BuildContext context, int index, Category item) {
    return TextButton(
      key: key,
      onPressed: () => _showCategoryModal(context, categories[index]),
      child: _buildCategoryContainer(item),
    );
  }

  Widget _buildCategoryContainer(Category item) {
    var authState = Provider.of<AuthState>(context);
    var headers = <String, String>{
      'Authorization': 'Bearer ${authState.token}'
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
                  categoriesEdit.showDeleteConfirmationDialog(context);
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
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
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
      'Authorization': 'Bearer ${authState.token}'
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
                      Navigator.pop(context);
                      widget.onArtifactAdded(boardArtefacts[index]);
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
                    final bool confirmed = await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete Artifact'),
                          content: Text(
                              'Are you sure you want to delete this artifact?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    print(confirmed);

                    if (confirmed) {
                      try {
                        print('Attempting to delete artifact...');

                        await artifactState.deleteArtifact(
                          category.artefacts![index].artefactId!,
                          token: authState.token!,
                        );

                        print('Server deletion successful');

                        if (mounted) {
                          bool wasLastItem = category.artefacts!.length == 1;

                          setState(() {
                            if (index >= 0 &&
                                index < category.artefacts!.length) {
                              category.artefacts!.removeAt(index);
                            }
                          });

                          // UI updates after state change
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              context.mounted
                                  ? ScaffoldMessenger.of(context
                                          .findRootAncestorStateOfType<
                                              NavigatorState>()!
                                          .context)
                                      .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Artifact deleted successfully'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                        elevation: 24,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    )
                                  : null;

                              if (wasLastItem && category.artefacts!.isEmpty) {
                                Navigator.of(context).pop();
                              }
                            }
                          });

                          onDelete();
                        }
                      } catch (e) {
                        print('Error during deletion: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to delete artifact'),
                              backgroundColor: Colors.red,
                              elevation: 24,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
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
        _showAddArtifactPopup(context, category);
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
            onSubmit: (name, imageBytes) {
              var artifactState =
                  Provider.of<ArtifactState>(context, listen: false);
              var authState = Provider.of<AuthState>(context, listen: false);
              var newCategory = Category(
                  name: name,
                  userId: authState.userId,
                  categoryIndex: 0,
                  image: imageBytes);
              artifactState.addCategory(newCategory, token: authState.token!);
            });
      },
    );
  }

  void _showEditCategoryPopup(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddItemPopup(
            isCategory: true,
            category: category,
            onSubmit: (name, imageBytes) {
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
            });
      },
    );
  }

  void _showAddArtifactPopup(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddItemPopup(
          isCategory: false,
          onSubmit: (name, bytes) async {
            var artifactState =
                Provider.of<ArtifactState>(context, listen: false);
            var authState = Provider.of<AuthState>(context, listen: false);
            var newArtifact = Artefact(
                categoryId: category.categoryId,
                userId: authState.userId,
                image: bytes);
            await artifactState.addArtifact(newArtifact,
                token: authState.token!);
          },
          title: "Tilføj Artifact",
        );
      },
    );
  }
}

class AddItemPopup extends StatefulWidget {
  Category? category;
  final bool isCategory;
  final void Function(String name, Uint8List? imageBytes) onSubmit;
  final String title;

  AddItemPopup({
    super.key,
    required this.isCategory,
    required this.onSubmit,
    this.category,
    this.title = 'Tilføj kategori',
  });

  @override
  State<AddItemPopup> createState() => _AddItemPopupState();
}

class _AddItemPopupState extends State<AddItemPopup> {
  Uint8List? imageBytes;
  final formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  void setGeneratedImage(String bytes) {
    final decodedBytes = base64Decode(bytes);
    setState(() {
      imageBytes = decodedBytes;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      nameController.text = widget.category!.name ?? '';
      _loadImageBytes();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadImageBytes() async {
    if (widget.category?.imageUrl != null) {
      final bytes = await getImageFromUrl(widget.category!.imageUrl);
      setState(() {
        imageBytes = bytes;
      });
    }
  }

  Future<Uint8List?> getImageFromUrl(String? imageUrl) async {
    if (imageUrl == null) {
      return null;
    }
    var headers = <String, String>{
      "Authorization":
          "Bearer ${Provider.of<AuthState>(context, listen: false).token}"
    };
    final response = await http.get(Uri.parse(imageUrl), headers: headers);
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var minHeight = screenSize.height * 0.8;
    var minWidth = screenSize.width * 0.6;

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: minHeight,
          maxWidth: minWidth,
          minHeight: 0,
          minWidth: 0,
        ),
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildForm(minWidth, formKey, nameController),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double minWidth, GlobalKey<FormState> formKey,
      TextEditingController nameController) {
    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: minWidth * 0.8,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return widget.isCategory
                          ? 'Et kategori navn er påkrævet'
                          : 'Et artefakt navn er påkrævet';
                    }
                    return null;
                  },
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    hintText:
                        widget.isCategory ? 'Kategori navn' : 'Artefakt navn',
                    hintStyle: TextStyle(color: Color(0xFF7C7C7C)),
                  ),
                ),
                SizedBox(height: 16),
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      imageBytes!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Image.asset(
                    'assets/images/no_image.png',
                    width: 150,
                    height: 150,
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton(
                    'Tag nyt billede', 'assets/images/camera_icon_filled.png',
                    onClick: _onTakePictureButtonPressed),
                SizedBox(width: 16),
                _buildButton('Upload', 'assets/images/folder_icon.png',
                    onClick: () async {
                  var result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                      withData: true);
                  if (result != null) {
                    setState(() {
                      imageBytes = result.files.single.bytes;
                    });
                  }
                }),
                SizedBox(width: 16),
                _buildButton('Lav med AI', 'assets/images/ai_file.png',
                    onClick: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          color: Colors.white,
                          width: 760,
                          height: 500,
                          child: AIPage(onImageProcessed: setGeneratedImage),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBADFB5),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    widget.onSubmit(nameController.text, imageBytes);
                    Navigator.of(context).pop();
                  }
                },
                child: Text(
                  widget.isCategory ? 'Tilføj kategori' : 'Tilføj artefakt',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Luk'),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onTakePictureButtonPressed() {
    if (CameraManager().cameras.isEmpty) {
      var snackMessage = 'No cameras available';
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        snackMessage = 'Camera not supported on desktop';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(snackMessage)),
      );
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => TakePictureScreen(
                camera: CameraManager().cameras.first,
                onImageChosen: (bytes) {
                  setState(() {
                    imageBytes = bytes;
                  });
                },
              )));
    }
  }

  Widget _buildButton(String label, String imageUrl,
      {void Function()? onClick}) {
    return GestureDetector(
      onTap: onClick,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(imageUrl),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
