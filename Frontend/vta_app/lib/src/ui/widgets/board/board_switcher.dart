import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/models/board_model.dart';

class BoardSwitcher extends StatelessWidget {
  final ArtifactBoardController controller;

  const BoardSwitcher({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuværende Tavle:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _showBoardSelectionSheet(context),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.activeBoard.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBoardSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => BoardSelectionSheet(
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class BoardSelectionSheet extends StatefulWidget {
  final ArtifactBoardController controller;
  final ScrollController scrollController;

  const BoardSelectionSheet({
    super.key,
    required this.controller,
    required this.scrollController,
  });

  @override
  State<BoardSelectionSheet> createState() => _BoardSelectionSheetState();
}

class _BoardSelectionSheetState extends State<BoardSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mine Tavler',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _showCreateBoardDialog,
                tooltip: 'Opret ny tavle',
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: widget.controller.availableBoards.length,
            itemBuilder: (context, index) {
              final board = widget.controller.availableBoards[index];
              final isActive = board.id == widget.controller.activeBoard.id;
              
              return _buildBoardCard(board, isActive);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoardCard(Board board, bool isActive) {
    return Card(
      elevation: isActive ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive 
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          widget.controller.switchBoard(board.id);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    board.showDirectional ? Icons.grid_view : Icons.swipe,
                    size: 32,
                    color: isActive ? Theme.of(context).primaryColor : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    board.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Theme.of(context).primaryColor : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.controller.availableBoards.length > 1)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red[300],
                  onPressed: () => _confirmDelete(board),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateBoardDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ny Tavle'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Titel',
            hintText: 'F.eks. Fælles, Pædagog',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                widget.controller.createBoard(textController.text);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close bottom sheet
              }
            },
            child: const Text('Opret'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Board board) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slet tavle?'),
        content: Text('Er du sikker på at du vil slette "${board.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nej'),
          ),
          TextButton(
            onPressed: () {
              widget.controller.deleteBoard(board.id);
              Navigator.pop(context);
              setState(() {}); // Refresh grid
            },
            child: const Text('Ja', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

