import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/models/board_model.dart';
import 'package:vta_app/src/ui/widgets/board/add_item_popup.dart';

const Color _barAccent = Color(0xFFF59E3D);

class BoardBar extends StatefulWidget {
  const BoardBar({
    super.key,
    required this.widgetHeight,
    required this.controller,
  });

  final double widgetHeight;
  final ArtifactBoardController controller;

  @override
  State<BoardBar> createState() => _BoardBarState();
}

class _BoardBarState extends State<BoardBar> {
  @override
  Widget build(BuildContext context) {
    final boards = widget.controller.availableBoards;
    final activeId = widget.controller.activeBoard.id;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: boards.length + 1, // +1 for the add tile
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: index < boards.length
              ? _buildBoardTile(boards[index], boards[index].id == activeId)
              : _buildAddTile(),
        );
      },
    );
  }

  Widget _buildBoardTile(Board board, bool isActive) {
    return SizedBox(
      width: widget.widgetHeight * 2,
      height: widget.widgetHeight,
      child: Material(
        color: Colors.white,
        elevation: isActive ? 3 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isActive
              ? const BorderSide(color: _barAccent, width: 2)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            widget.controller.switchBoard(board.id);
            setState(() {});
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              children: [
                Text(
                  board.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: board.image != null
                      ? Image.memory(board.image!, fit: BoxFit.contain)
                      : const Center(
                          child: Icon(Icons.grid_view, color: Colors.black26),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile() {
    return SizedBox(
      width: widget.widgetHeight * 2,
      height: widget.widgetHeight,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _showAddBoardPopup,
          child: const Center(
            child: Icon(Icons.add_circle_outline, color: _barAccent),
          ),
        ),
      ),
    );
  }

  void _showAddBoardPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (BuildContext context) {
        return AddItemPopup(
          isCategory: true,
          itemNoun: 'tavle',
          title: 'Tilføj tavle',
          onSubmit:
              (String name, Uint8List? imageBytes, Uint8List? soundBytes) {
            widget.controller.createBoard(name, image: imageBytes);
            setState(() {});
          },
        );
      },
    );
  }
}