import 'package:flutter/material.dart';
import 'categories_widget.dart';

class CategoriesEdit extends StatelessWidget {
  final String categoryName;
  final String? imageUrl;
  final String categoryId;
  final Function onEdit;

  const CategoriesEdit({
    super.key,
    required this.categoryName,
    this.imageUrl,
    required this.onEdit,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        print("Long press detected on $categoryName");
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

  void showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete the category "$categoryName"?'),
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
                deleteCategory(context, categoryId); // Call the delete function
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void deleteCategory(BuildContext context, String categoryId) {
    // Implement your delete functionality here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted category: $categoryId')),
    );
  }
}
