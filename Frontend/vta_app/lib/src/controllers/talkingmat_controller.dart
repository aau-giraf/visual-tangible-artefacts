import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'dart:collection';

// Internal class to watch for direct list mutations
class _WatchedList extends ListBase<BoardArtefact>
    implements List<BoardArtefact> {
  final List<BoardArtefact> _list;
  final TalkingmatController _controller;

  _WatchedList(this._list, this._controller);

  @override
  int get length => _list.length;

  @override
  set length(int newLength) {
    final int oldLength = _list.length;
    if (newLength != oldLength) {
      debugPrint(
          '[TalkingmatController] _WatchedList - length changed from $oldLength to $newLength');
      if (newLength == 0 && oldLength > 0) {
        debugPrint(
            '[TalkingmatController] WARNING: List cleared via length setter!');
        try {
          throw Exception('Stack trace for debugging');
        } catch (e, stackTrace) {
          debugPrint('[TalkingmatController] Stack trace: $stackTrace');
        }
      }
    }
    _list.length = newLength;
    _controller._notifyListeners();
  }

  @override
  BoardArtefact operator [](int index) => _list[index];

  @override
  void operator []=(int index, BoardArtefact value) {
    _list[index] = value;
    _controller._notifyListeners();
  }

  @override
  void clear() {
    final int oldLength = _list.length;
    debugPrint(
        '[${_controller._instanceId}] _WatchedList - clear() called! List had $oldLength items');
    if (oldLength > 0) {
      debugPrint(
          '[${_controller._instanceId}] WARNING: List cleared via clear()! Stack trace:');
      try {
        throw Exception('Stack trace for debugging');
      } catch (e, stackTrace) {
        debugPrint('[${_controller._instanceId}] Stack trace: $stackTrace');
      }
    }
    _list.clear();
    _controller._notifyListeners();
  }

  @override
  bool remove(Object? value) {
    final bool result = _list.remove(value);
    if (result) {
      debugPrint(
          '[TalkingmatController] _WatchedList - remove() called, item removed');
      _controller._notifyListeners();
    }
    return result;
  }

  @override
  BoardArtefact removeAt(int index) {
    final BoardArtefact result = _list.removeAt(index);
    debugPrint('[TalkingmatController] _WatchedList - removeAt($index) called');
    _controller._notifyListeners();
    return result;
  }

  @override
  void removeWhere(bool Function(BoardArtefact) test) {
    final int oldLength = _list.length;
    _list.removeWhere(test);
    final int removed = oldLength - _list.length;
    if (removed > 0) {
      debugPrint(
          '[TalkingmatController] _WatchedList - removeWhere() removed $removed item(s)');
      _controller._notifyListeners();
    }
  }

  // Delegate other methods to the underlying list
  @override
  void add(BoardArtefact element) => _list.add(element);

  @override
  void addAll(Iterable<BoardArtefact> iterable) => _list.addAll(iterable);

  @override
  Iterable<BoardArtefact> get reversed => _list.reversed;

  @override
  void sort([int Function(BoardArtefact, BoardArtefact)? compare]) =>
      _list.sort(compare);
}

class TalkingmatController extends ValueNotifier<List<BoardArtefact>> {
  final Function(BoardArtefact)? onArtefactAdded;
  final String _instanceId;
  static int _instanceCounter = 0;

  // Expose notifyListeners to _WatchedList
  void _notifyListeners() => notifyListeners();

  TalkingmatController(
      {List<BoardArtefact>? initialArtifacts, this.onArtefactAdded})
      : _instanceId = 'TalkingmatController_${_instanceCounter++}',
        super(initialArtifacts ?? []) {
    debugPrint(
        '[$_instanceId] CREATED with ${initialArtifacts?.length ?? 0} initial artifacts');
    // Wrap the list in a way that detects direct mutations
    // Create a proxy list that tracks changes
    super.value = _WatchedList(value, this);
    debugPrint('[$_instanceId] Initialized with ${value.length} artifacts');
  }

  @override
  set value(List<BoardArtefact> newValue) {
    final int oldLength = value.length;
    final int newLength = newValue.length;

    // Always log setter calls for debugging
    debugPrint(
        '[$_instanceId] value SETTER CALLED - oldLength: $oldLength, newLength: $newLength');

    if (oldLength != newLength) {
      debugPrint(
          '[$_instanceId] value SETTER - Count changed from $oldLength to $newLength');

      if (oldLength > newLength && newLength == 0) {
        debugPrint(
            '[$_instanceId] WARNING: Controller value cleared from $oldLength to 0!');
        // Print stack trace for debugging
        try {
          throw Exception('Stack trace for debugging');
        } catch (e, stackTrace) {
          debugPrint('[$_instanceId] Stack trace: $stackTrace');
        }
      } else if (oldLength > newLength) {
        debugPrint(
            '[$_instanceId] value SETTER - Artifacts removed (${oldLength - newLength} removed)');
      } else {
        debugPrint(
            '[$_instanceId] value SETTER - Artifacts added (${newLength - oldLength} added)');
      }
    } else if (oldLength == 0 && newLength == 0) {
      debugPrint(
          '[$_instanceId] WARNING: Setting empty list to empty list - stack trace:');
      try {
        throw Exception('Stack trace for debugging');
      } catch (e, stackTrace) {
        debugPrint('[$_instanceId] Stack trace: $stackTrace');
      }
    }

    // If newValue is not a _WatchedList, wrap it
    if (newValue is! _WatchedList) {
      super.value = _WatchedList(newValue, this);
    } else {
      super.value = newValue;
    }
  }

  void addArtifact(BoardArtefact artefact) {
    final String artifactId = artefact.baseArtefact?.artefactId ?? 'unknown';
    debugPrint(
        '[$_instanceId] Adding artifact ID:$artifactId, position: ${artefact.position}, total count: ${value.length + 1}');
    value.add(artefact);
    onArtefactAdded?.call(artefact);
    debugPrint('[$_instanceId] Artifact added, new count: ${value.length}');
    notifyListeners();
  }

  void removeArtifact(BoardArtefact artefact) {
    final String artifactId = artefact.baseArtefact?.artefactId ?? 'unknown';
    final int countBefore = value.length;
    debugPrint(
        '[$_instanceId] Removing artifact ID:$artifactId, current count: $countBefore');
    // Prefer removing by savedArtefactId (instance id) to avoid removing all duplicates
    if (artefact.savedArtefactId != null) {
      value.removeWhere(
          (item) => item.savedArtefactId == artefact.savedArtefactId);
    } else {
      // Fallback: remove a single instance matching the artefactId
      final idx =
          value.indexWhere((item) => item.artefactId == artefact.artefactId);
      if (idx != -1) {
        value.removeAt(idx);
      }
    }
    final int removedCount = countBefore - value.length;
    debugPrint(
        '[$_instanceId] Removed $removedCount artifact(s), new count: ${value.length}');
    notifyListeners();
  }

  void removeAllArtifacts({BuildContext? context}) {
    if (context != null && context.mounted) {
      showRemoveAllArtifactsAlert(context);
    }
  }

  /// Set name visibility for all artifacts on the board
  void setNamesVisibleForAll(bool visible) {
    for (final artifact in value) {
      artifact.nameVisible = visible;
    }
  }

  /// Force a rebuild of all artifacts on the board
  /// Useful when a base artefact property changes (like nameShown)
  void refresh() {
    notifyListeners();
  }

  void showRemoveAllArtifactsAlert(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Bekræft"),
            content: Text("Er du sikker på at du vil fjerne alle artefakter?"),
            actions: <Widget>[
              TextButton(
                child: Text("Annuller"),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: Text("Ja"),
                onPressed: () {
                  value.clear();
                  Navigator.of(context).pop(); // Close the dialog
                  notifyListeners();
                },
              ),
            ],
          );
        });
  }
}
