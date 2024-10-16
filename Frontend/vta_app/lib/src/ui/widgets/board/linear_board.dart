import 'package:flutter/material.dart';
import 'linear_board_button.dart'; // Import the LinearBoardButton widget

class LinearBoard extends StatelessWidget {
  const LinearBoard({Key? key}) : super(key: key);

  static const IconData cropLandscapeRounded = IconData(0xf685, fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linear Board'),
        automaticallyImplyLeading: false, // Remove the back arrow
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Box 1')),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.black,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Box 2')),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.black,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Box 3')),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Colors.black,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    color: Colors.grey[300],
                    child: const Center(child: Text('Box 4')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const Align(
        alignment: Alignment(-0.9, -0.8), // Adjust the alignment as needed
        child: LinearBoardButton(), // Use the LinearBoardButton widget
      ),
    );
  }
}