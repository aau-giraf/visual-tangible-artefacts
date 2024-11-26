import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vta_app/src/controllers/board_controller.dart';

class RemoveAllDialog extends StatelessWidget {
  final BoardController controller;
  RemoveAllDialog({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Confirm"),
      content: Text("Are you sure you want to remove all artifacts?"),
      actions: <Widget>[
        TextButton(
          child: Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
        TextButton(
          child: Text("Yes"),
          onPressed: () {
            controller.removeArtefacts(context);
            Navigator.of(context).pop(); // Close the dialog
          },
        ),
      ],
    );
  }
}

