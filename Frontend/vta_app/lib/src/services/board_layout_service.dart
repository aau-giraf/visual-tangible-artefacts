// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/models/board_layout.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';

class BoardLayoutService {
  final ApiProvider _apiProvider;
  final Token _token;

  BoardLayoutService({ApiProvider? apiProvider, Token? token})
      : _apiProvider = apiProvider ?? GetIt.instance.get<ApiProvider>(),
        _token = token ?? GetIt.instance.get<Token>();

  /// Get all saved boards for the current user
  Future<List<BoardLayoutResponse>?> getBoards() async {
    try {
      final response = await _apiProvider.fetchAsJson(
        'Boards',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((board) =>
                BoardLayoutResponse.fromJson(board as Map<String, dynamic>))
            .toList();
      }
      return null;
    } catch (e) {
      print('Error getting boards: $e');
      return null;
    }
  }

  /// Get a specific board layout by ID
  Future<BoardLayoutResponse?> getBoard(String boardId) async {
    try {
      final response = await _apiProvider.fetchAsJson(
        'Boards/$boardId',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BoardLayoutResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting board: $e');
      return null;
    }
  }

  /// Save a new board layout
  Future<BoardLayoutResponse?> saveBoard(SaveBoardRequest request) async {
    try {
      // debug logs removed

      final response = await _apiProvider.postAsJson(
        'Boards',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
        body: request.toJson(),
      );

      // debug logs removed

      if (response != null && response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BoardLayoutResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error saving board: $e');
      return null;
    }
  }

  /// Update an existing board layout
  Future<BoardLayoutResponse?> updateBoard(
      String boardId, SaveBoardRequest request) async {
    try {
      final response = await _apiProvider.putAsJson(
        'Boards/$boardId',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
        body: request.toJson(),
      );

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return BoardLayoutResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error updating board: $e');
      return null;
    }
  }

  /// Update the position and size of a specific artefact on a board
  Future<bool> updateArtefactLayout(
      String boardId, UpdateArtefactLayoutRequest request) async {
    try {
      final response = await _apiProvider.patchAsJson(
        'Boards/$boardId/artefacts',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
        body: request.toJson(),
      );

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('Error updating artefact layout: $e');
      return false;
    }
  }

  /// Delete a saved board
  Future<bool> deleteBoard(String boardId) async {
    try {
      final response = await _apiProvider.delete(
        'Boards/$boardId',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('Error deleting board: $e');
      return false;
    }
  }

  /// Delete a specific saved artefact instance from a board
  Future<bool> deleteSavedArtefact(
      String boardId, String savedArtefactId) async {
    try {
      final response = await _apiProvider.delete(
        'Boards/$boardId/artefacts/$savedArtefactId',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('Error deleting saved artefact: $e');
      return false;
    }
  }

  /// Delete all saved artefacts on a board (clear board)
  Future<bool> deleteAllSavedArtefacts(String boardId) async {
    try {
      final response = await _apiProvider.delete(
        'Boards/$boardId/artefacts',
        headers: {
          'Authorization': 'Bearer ${_token.value}',
        },
      );

      return response != null && response.statusCode == 200;
    } catch (e) {
      print('Error deleting all saved artefacts: $e');
      return false;
    }
  }
}
