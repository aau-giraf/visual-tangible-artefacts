import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_board_controller.dart';
import 'package:vta_app/src/models/board_model.dart';

const Color _viewBackground = Color(0xFFFBF7F4);
const Color _viewAccent = Color(0xFFF59E3D);

class BoardsView extends StatefulWidget {
  const BoardsView({
    super.key,
    required this.isOpen,
    required this.controller,
    required this.onClose,
    this.borderRadius = BorderRadius.zero,
  });

  final bool isOpen;
  final ArtifactBoardController controller;
  final VoidCallback onClose; // closes the whole hub
  final BorderRadius borderRadius;

  @override
  State<BoardsView> createState() => _BoardsViewState();
}

class _BoardsViewState extends State<BoardsView> {
  bool _editing = false;

  @override
  void didUpdateWidget(BoardsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Leave edit mode every time the view is opened
    if (!oldWidget.isOpen && widget.isOpen) {
      _editing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final boards = widget.controller.availableBoards;
    final activeId = widget.controller.activeBoard.id;
    final wide = MediaQuery.of(context).size.width > 600;
    final canDelete = _editing && boards.length > 1;

    return Material(
      color: _viewBackground,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
                wide ? 36 : 16, wide ? 28 : 16, wide ? 84 : 64, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 360 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: boards.length,
                  itemBuilder: (context, index) {
                    final board = boards[index];
                    return _BoardTile(
                      board: board,
                      isActive: board.id == activeId,
                      showDelete: canDelete,
                      onTap: () {
                        widget.controller.switchBoard(board.id);
                        widget.onClose();
                      },
                      onDelete: () => _confirmDelete(board),
                    );
                  },
                );
              },
            ),
          ),

          // Close (X)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Luk',
              iconSize: 28,
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),

          // Edit + add buttons
          Positioned(
            top: 60,
            right: 14,
            child: Column(
              children: [
                _SideButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Rediger tavler',
                  active: _editing,
                  onTap: () => setState(() => _editing = !_editing),
                ),
                const SizedBox(height: 10),
                _SideButton(
                  icon: Icons.add,
                  tooltip: 'Opret ny tavle',
                  onTap: _showCreateBoardDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateBoardDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuller'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                widget.controller.createBoard(textController.text);
                Navigator.pop(dialogContext);
                setState(() {}); // Refresh grid
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Slet tavle?'),
        content: Text('Er du sikker på at du vil slette "${board.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Nej'),
          ),
          TextButton(
            onPressed: () {
              widget.controller.deleteBoard(board.id);
              Navigator.pop(dialogContext);
              setState(() {}); // Refresh grid
            },
            child: const Text('Ja', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  const _BoardTile({
    required this.board,
    required this.isActive,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  final Board board;
  final bool isActive;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Material(
                  color: Colors.white,
                  elevation: isActive ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: isActive
                        ? const BorderSide(color: Colors.white, width: 2)
                        : BorderSide.none,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: CustomPaint(painter: _GridPreviewPainter()),
                    ),
                  ),
                ),
              ),
              if (showDelete)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red[300],
                    onPressed: onDelete,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          board.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Placeholder thumbnail: the grid lines from the Figma cards
class _GridPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9E9E9E)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? const Color(0xFFFFE9CC) : Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 22, color: _viewAccent),
          ),
        ),
      ),
    );
  }
}