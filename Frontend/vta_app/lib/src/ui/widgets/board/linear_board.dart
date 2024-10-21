import 'package:flutter/material.dart';
import 'linear_board_button.dart'; // Import the LinearBoardButton widget

class LinearBoard extends StatelessWidget {
  const LinearBoard({super.key});

  static const IconData cropLandscapeRounded =
      IconData(0xf685, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linear Board'),
        automaticallyImplyLeading: false, // Remove the back arrow
      ),
      body: Center( // Background box container
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9, // Adjust width as needed
          height: MediaQuery.of(context).size.height * 0.6, // Adjust height as needed
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 2,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBox(context, 'Box 1'),
              _buildVerticalDivider(context),
              _buildBox(context, 'Box 2'),
              _buildVerticalDivider(context),
              _buildBox(context, 'Box 3'),
              _buildVerticalDivider(context),
              _buildBox(context, 'Box 4'),
            ],
          ),
        ),
      ),
      floatingActionButton: Align(
        alignment: const Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: const LinearBoardButton(), // Use the LinearBoardButton widget
      ),
    );
  }

  Widget _buildBox(BuildContext context, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _showCategories(context, title);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.height * 0.4,
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      _showCategories(context, title);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      width: 1,
      color: Colors.black,
    );
  }

   void _showCategories(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
                maxWidth: MediaQuery.of(context).size.width,
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Center(
                child: Text('Categories for $title'),
              ),
            ),
          ],
        );
      },
    );
  }
}
