import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

var myMargin = const EdgeInsets.all(3);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const title = 'Horizontal List';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: const Align(
          alignment: Alignment.bottomCenter,
          child: DynamicListView(),
        ),
      ),
    );
  }
}

class DynamicListView extends StatefulWidget {
  const DynamicListView({super.key});

  @override
  _DynamicListViewState createState() => _DynamicListViewState();
}

class _DynamicListViewState extends State<DynamicListView> {
  // List to hold the containers
  final List<ContainerInfo> _containers = [
    ContainerInfo(color: Colors.red),
    ContainerInfo(color: Colors.blue),
    ContainerInfo(color: Colors.green),
    ContainerInfo(color: Colors.yellow),
  ];

  // Boolean to track whether the remove buttons are visible
  bool _showRemoveButtons = false;

  // Method to add a new container
  void _addContainer() {
    setState(() {
      _containers.add(ContainerInfo(color: Colors.purple)); // Default color
    });
  }

  // Method to remove a container at a specific index
  void _removeContainer(int index) {
    setState(() {
      if (_containers.isNotEmpty && index < _containers.length) {
        _containers.removeAt(index);
      }
    });
  }

  // Method to show the dialog to edit a container's color and image
  void _showEditDialog(int index) {
    Color selectedColor = _containers[index].color; // Now initialized as non-nullable
    String? imageUrl = _containers[index].imageUrl;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Container"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select a Color:"),
                  Wrap(
                    spacing: 5,
                    children: Colors.primaries.map((color) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedColor = color;
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 20,
                          child: selectedColor == color
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setStateDialog(() {
                        imageUrl = "assets/sample_image.png"; // Example local asset image
                      });
                    },
                    child: const Text("Add Picture"),
                  ),
                  if (imageUrl != null)
                    Image.asset(
                      imageUrl!,
                      width: 100,
                      height: 100,
                    ),
                ],
              ),
              actions: [
                // Remove Container Button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _removeContainer(index); // Remove the container
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Remove Container"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      // Save the selected color and image to the container
                      _containers[index].color = selectedColor;
                      _containers[index].imageUrl = imageUrl;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Method to toggle the visibility of the remove buttons
  void _toggleRemoveButtons() {
    setState(() {
      _showRemoveButtons = !_showRemoveButtons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 150, // Increased height to accommodate image
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Render existing containers with optional edit and remove buttons
          ...List.generate(_containers.length, (index) {
            return Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 160,
                  margin: myMargin,
                  color: _containers[index].color,
                  child: _containers[index].imageUrl != null
                      ? Image.asset(
                          _containers[index].imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : null, // Display image if available
                ),
                // Conditionally show the edit button that triggers a dialog
                if (_showRemoveButtons)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showEditDialog(index), // Show edit pop-up
                    ),
                  ),
              ],
            );
          }),
          // The "Add Container" button
          Container(
            width: 160,
            margin: myMargin,
            child: ElevatedButton(
              onPressed: _addContainer, // Add a new container
              child: const Text("Add Container"),
            ),
          ),
          // The toggle button for enabling/disabling remove buttons
          Container(
            width: 160,
            margin: myMargin,
            child: ElevatedButton(
              onPressed: _toggleRemoveButtons, // Toggle visibility of remove buttons
              child: Text(_showRemoveButtons ? "Hide Edit" : "Show Edit"),
            ),
          ),
        ],
      ),
    );
  }
}

// ContainerInfo class to hold color and image for each container
class ContainerInfo {
  Color color;
  String? imageUrl;

  ContainerInfo({required this.color, this.imageUrl});
}