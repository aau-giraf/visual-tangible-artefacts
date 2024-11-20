import 'package:flutter/material.dart';
import 'categories_widget.dart';

class CategoriesEdit extends StatelessWidget {
  final String categoryName;
  final String? imageUrl;
  final Function onEdit;
  final Function onDelete;

  const CategoriesEdit({
    Key? key,
    required this.categoryName,
    this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        print("Long press detected on $categoryName");
    _showEditDeletePopup(context);
  },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: imageUrl != null
              ? Image.network(imageUrl!, fit: BoxFit.contain)
              : Text(
                  categoryName,
                  style: const TextStyle(color: Colors.black),
                ),
        ),
      ),
    );
  }

  void _showEditDeletePopup(BuildContext context) {
    print('Showing edit/delete popup for $categoryName');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit', style: TextStyle(color: Colors.blue)),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
                showDeleteConfirmationDialog(context);
                },
            ),
          ],
        );
      },
    );
  }


 void showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the category "$categoryName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onDelete(); // Call the delete function
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

class CategoriesDelete {
  static void deleteCategory(BuildContext context, String categoryName) {
    // Implement your delete functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted category: $categoryName')),
    );
  }
}