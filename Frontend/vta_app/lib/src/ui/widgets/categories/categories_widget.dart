import 'dart:convert';
import 'dart:io';
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
import 'package:vta_app/src/utilities/services/camera_service.dart';

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
  Category? _selectedCategory;
  late List<Category> categories;

  @override
  void initState() {
    super.initState();
    categories = widget.categories;
  }

 @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.widgetHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 for Add button
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return _buildAddCategoryButton();
          }
          return _buildCategoryItem(context, index);
        },
        separatorBuilder: (context, index) => const SizedBox(width: 10),
      ),
    );
  }


  

 Widget _buildCategoryList() {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length + 1, //+1 room for add button
      itemBuilder: (context, index) {
        if (index == categories.length) {
          return _buildAddCategoryButton();
        }
        return _buildCategoryItem(context, index);
      },
      separatorBuilder: (context, index) => const SizedBox(width: 10),
    );
    
  }


  Widget _buildAddCategoryButton() {
    return SizedBox(
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


  Widget _buildCategoryItem(BuildContext context, int index) {
  final item = categories[index];

  return GestureDetector(
    onLongPress: () {
      _showCategoryEditModal(context, item); // Show modal on long press
    },
    child: TextButton(
      onPressed: () => _showCategoryModal(context, item), // Optional: Add tap handling
      child: _buildCategoryContainer(item),
    ),
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
      widget.isMatrixVisible(!_isMatrixVisible);
      _isMatrixVisible = !_isMatrixVisible;
    });
  }

// ModalSheet for editing and deleting categories
  void _showCategoryEditModal(BuildContext context, Category category) {
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
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Close the modal
                  final categoriesEdit = CategoriesEdit(
                    categoryName: category.name!,
                    imageUrl: category.imageUrl,
                    onEdit: () {
                      MaterialPageRoute(builder: (context) => AddPicturePage());
                    }, // Pass edit functionality if needed
                    onDelete: () {
                      // Perform deletion using CategoriesEdit logic
                      setState(() {
                        categories.remove(category); // Reflect UI changes
                      });
                    },
                  );
                  categoriesEdit.showDeleteConfirmationDialog(context);
                },
              ),
              TextButton(
                onPressed: () {
                  //CategoriesEdit.deleteCategory(context, category);
                  Navigator.pop(context); // Close the modal
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildImageGrid(Category category) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: category.artefacts!.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddArtifactButton(category);
        } else {
          return _buildImageGridItem(context, index - 1, category);
        }
      },
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

class CategoryPopup extends StatefulWidget {
  const CategoryPopup({super.key});

  @override
  State<CategoryPopup> createState() => _CategoryPopupState();
}

class _CategoryPopupState extends State<CategoryPopup> {
  Uint8List? imageBytes;
  var formKey = GlobalKey<FormState>();
  TextEditingController categoryNameController = TextEditingController();
  void setGeneratedImage(String bytes) {
    final decodedBytes = base64Decode(bytes);
    setState(() {
      imageBytes = decodedBytes;
    });
  }

  @override
  void dispose() {
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var minHeight = screenSize.height * 0.7;
    var minWidth = screenSize.width * 0.5;
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: minHeight,
          maxWidth: minWidth,
          minHeight: 300,
          minWidth: 250,
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
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            Widget page;
            switch (settings.name) {
              case '/ai':
                page = Padding(
                  padding: EdgeInsets.all(20),
                  child: AIPage(onImageProcessed: setGeneratedImage),
                );
                break;
              default:
                page = Scrollbar(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildAddCategoryForm(minWidth, formKey,
                          categoryNameController, navigatorKey, context),
                    ),
                  ),
                );
            }
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddCategoryForm(
      double minWidth,
      GlobalKey<FormState> formKey,
      TextEditingController categoryNameController,
      GlobalKey<NavigatorState> navigatorKey,
      BuildContext context) {
    return Column(
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
        SizedBox(height: 10),
        SizedBox(
          width: minWidth * 0.5,
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Et navn er påkrævet';
                    }
                    return null;
                  },
                  controller: categoryNameController,
                  style: TextStyle(color: Colors.black),
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
                FormField(
                  validator: (value) =>
                      imageBytes == null ? 'Et billede er påkrævet' : null,
                  builder: (FormFieldState state) {
                    return Container();
                  },
                ),
                SizedBox(height: 20),
                imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        width: 200,
                        height: 200,
                      )
                    : Image.asset(
                        'assets/images/no_image.png',
                        width: 200,
                        height: 200,
                      ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(
                  'Tag nyt billede', 'assets/images/camera_icon_filled.png',
                  onClick: () => _onTakePictureButtonPressed()),
              SizedBox(width: 20),
              _buildButton('Upload', 'assets/images/folder_icon.png',
                  onClick: () async {
                var result = await FilePicker.platform.pickFiles(
                    type: FileType.image, allowMultiple: false, withData: true);
                if (result != null) {
                  setState(() {
                    imageBytes = result.files.single.bytes;
                  });
                }
              }),
              SizedBox(width: 20),
              _buildButton('Lav med AI', 'assets/images/ai_file.png',
                  onClick: () {
                navigatorKey.currentState?.pushNamed('/ai');
              }),
            ],
          ),
        ),
        SizedBox(height: 20),
        Column(
          children: [
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Color(0xFFBADFB5)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  var artifactState =
                      Provider.of<ArtifactState>(context, listen: false);
                  var authState =
                      Provider.of<AuthState>(context, listen: false);
                  var newCategory = Category(
                      name: categoryNameController.text,
                      userId: authState.userId,
                      categoryIndex: 0,
                      image: imageBytes);
                  artifactState.addCategory(newCategory,
                      token: authState.token!);
                  Navigator.of(context).pop();
                }
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
    );
  }

  void _onTakePictureButtonPressed() {
    {
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

class AddItemPopup extends StatefulWidget {
  final bool isCategory;
  final void Function(String name, Uint8List? imageBytes) onSubmit;
  final String title;

  const AddItemPopup({
    super.key,
    required this.isCategory,
    required this.onSubmit,
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
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var minHeight = screenSize.height * 0.8;
    var minWidth = screenSize.width * 0.6;
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: minHeight,
          maxWidth: minWidth,
          minHeight: 400,
          minWidth: 300,
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
        child: Navigator(
          key: navigatorKey,
          onGenerateRoute: (RouteSettings settings) {
            Widget page;
            switch (settings.name) {
              case '/ai':
                page = Padding(
                  padding: EdgeInsets.all(20),
                  child: AIPage(onImageProcessed: setGeneratedImage),
                );
                break;
              default:
                page = SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildForm(
                        minWidth, formKey, nameController, navigatorKey),
                  ),
                );
            }
            return PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm(
      double minWidth,
      GlobalKey<FormState> formKey,
      TextEditingController nameController,
      GlobalKey<NavigatorState> navigatorKey) {
    return Column(
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
          child: Form(
            key: formKey,
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
        ),
        SizedBox(height: 16),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
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
                  navigatorKey.currentState?.pushNamed('/ai');
                }),
              ],
            ),
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
