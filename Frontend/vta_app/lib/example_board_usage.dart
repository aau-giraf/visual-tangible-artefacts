// Example usage of the board layout functionality

import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/talking_mat.dart';
import 'package:vta_app/src/models/board_layout.dart';
import 'package:vta_app/src/controllers/talkingmat_controller.dart';

// 1. Basic usage in a parent widget:

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  final GlobalKey<TalkingMatState> _talkingMatKey = GlobalKey<TalkingMatState>();
  late final TalkingmatController _talkingMatController;
  List<BoardLayoutResponse>? _savedBoards;

  @override
  void initState() {
    super.initState();
    _talkingMatController = TalkingmatController();
    _loadSavedBoards();
  }

  Future<void> _loadSavedBoards() async {
    final boards = await _talkingMatKey.currentState?.getSavedBoards();
    setState(() {
      _savedBoards = boards;
    });
  }

  Future<void> _saveCurrentBoard() async {
    final boardName = 'My Board ${DateTime.now().millisecondsSinceEpoch}';
    final boardId = await _talkingMatKey.currentState?.saveBoardAs(boardName);
    if (boardId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Board saved as "$boardName"')),
      );
      _loadSavedBoards();
    }
  }

  Future<void> _loadBoard(String boardId) async {
    await _talkingMatKey.currentState?.loadBoard(boardId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Board loaded')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Board Layout Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCurrentBoard,
            tooltip: 'Save Current Board',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.folder_open),
            onSelected: _loadBoard,
            itemBuilder: (context) {
              return _savedBoards?.map((board) {
                    return PopupMenuItem<String>(
                      value: board.boardId,
                      child: Text(board.name),
                    );
                  }).toList() ??
                  [];
            },
            tooltip: 'Load Saved Board',
          ),
        ],
      ),
      body: TalkingMat(
        key: _talkingMatKey,
        controller: _talkingMatController,
        artifacts: [], // Your initial artifacts
      ),
    );
  }
}

// 2. How the auto-save works:

/*
Auto-save functionality:

1. When you move an artefact on the board:
   - The _updateArtifactPosition method is called
   - This triggers _scheduleAutoSave() 
   - After 2 seconds of inactivity, the board layout is automatically saved

2. When you resize an artefact:
   - The sizeNotifier listener detects the change
   - This triggers _scheduleAutoSave()
   - After 2 seconds of inactivity, the board layout is automatically saved

3. The auto-save only works if there's a current board loaded (_currentBoardId is set)
   - You need to either load an existing board or save the board first
   - Once a board ID is established, all position and size changes are auto-saved

API Endpoints available:
- GET /api/Boards - Get all saved boards
- GET /api/Boards/{boardId} - Get specific board
- POST /api/Boards - Save new board
- PUT /api/Boards/{boardId} - Update entire board
- PATCH /api/Boards/{boardId}/artefacts - Update single artefact position/size
- DELETE /api/Boards/{boardId} - Delete board
*/
