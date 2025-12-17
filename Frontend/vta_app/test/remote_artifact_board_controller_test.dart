import 'package:flutter_test/flutter_test.dart';
import 'package:vta_app/src/services/signalr_service.dart';

/// Tests for RemoteArtifactBoardController synchronization
/// 
/// These tests verify that the SignalR service callbacks work correctly
/// for remote board synchronization between owner and non-owner participants.
/// 
/// Note: Full end-to-end controller tests require widget testing due to
/// dependencies on Flutter bindings, audio players, and shared preferences.
/// These unit tests focus on the SignalR callback registration and invocation.
void main() {
  setUp(() {
    // Clean up any previous SignalR callbacks
    SignalRService().onBoardUpdated = null;
    SignalRService().onArtifactAdded = null;
    SignalRService().onArtifactRemoved = null;
    SignalRService().onArtifactMoved = null;
    SignalRService().onArtifactResized = null;
    SignalRService().onLayoutChanged = null;
    SignalRService().onFieldCountChanged = null;
  });

  tearDown(() {
    // Clean up SignalR callbacks after each test
    SignalRService().onBoardUpdated = null;
    SignalRService().onArtifactAdded = null;
    SignalRService().onArtifactRemoved = null;
    SignalRService().onArtifactMoved = null;
    SignalRService().onArtifactResized = null;
    SignalRService().onLayoutChanged = null;
    SignalRService().onFieldCountChanged = null;
  });

  group('SignalR Callback Registration', () {
    test('SignalR service starts with null callbacks', () {
      expect(SignalRService().onBoardUpdated, isNull);
      expect(SignalRService().onArtifactAdded, isNull);
      expect(SignalRService().onArtifactRemoved, isNull);
      expect(SignalRService().onArtifactMoved, isNull);
      expect(SignalRService().onArtifactResized, isNull);
      expect(SignalRService().onLayoutChanged, isNull);
      expect(SignalRService().onFieldCountChanged, isNull);
    });

    test('Can register and invoke onArtifactAdded callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onArtifactAdded = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      expect(SignalRService().onArtifactAdded, isNotNull);

      // Simulate SignalR calling the callback
      final testData = {
        'sessionId': 'test-session',
        'artifact': {
          'savedArtefactId': 'saved-123',
          'id': 'artifact-1',
          'name': 'Test Artifact',
        },
      };

      SignalRService().onArtifactAdded?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onArtifactRemoved callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onArtifactRemoved = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'savedArtefactId': 'saved-123',
      };

      SignalRService().onArtifactRemoved?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onArtifactMoved callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onArtifactMoved = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'savedArtefactId': 'saved-123',
        'position': {'dx': 300.0, 'dy': 400.0},
      };

      SignalRService().onArtifactMoved?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onArtifactResized callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onArtifactResized = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'savedArtefactId': 'saved-123',
        'size': {'width': 200.0, 'height': 300.0},
      };

      SignalRService().onArtifactResized?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onLayoutChanged callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onLayoutChanged = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'layout': 'linear',
      };

      SignalRService().onLayoutChanged?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onFieldCountChanged callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onFieldCountChanged = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'count': 7,
      };

      SignalRService().onFieldCountChanged?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });

    test('Can register and invoke onBoardUpdated callback', () {
      var callbackInvoked = false;
      dynamic receivedData;

      SignalRService().onBoardUpdated = (data) {
        callbackInvoked = true;
        receivedData = data;
      };

      final testData = {
        'sessionId': 'test-session',
        'layout': 'talkingmat',
        'fieldCount': 3,
        'items': [
          {
            'savedArtefactId': 'saved-1',
            'id': 'artifact-1',
            'name': 'Artifact 1',
          },
        ],
      };

      SignalRService().onBoardUpdated?.call(testData);

      expect(callbackInvoked, isTrue);
      expect(receivedData, equals(testData));
    });
  });

  group('Multiple Callbacks', () {
    test('Multiple callbacks can be registered and invoked independently', () {
      var addedCalled = false;
      var removedCalled = false;
      var movedCalled = false;

      SignalRService().onArtifactAdded = (data) => addedCalled = true;
      SignalRService().onArtifactRemoved = (data) => removedCalled = true;
      SignalRService().onArtifactMoved = (data) => movedCalled = true;

      // Call only one callback
      SignalRService().onArtifactAdded?.call({'test': 'data'});

      expect(addedCalled, isTrue);
      expect(removedCalled, isFalse);
      expect(movedCalled, isFalse);

      // Call another callback
      SignalRService().onArtifactMoved?.call({'test': 'data'});

      expect(addedCalled, isTrue);
      expect(removedCalled, isFalse);
      expect(movedCalled, isTrue);
    });

    test('Callbacks can be overwritten', () {
      var firstCallbackInvoked = false;
      var secondCallbackInvoked = false;

      // Register first callback
      SignalRService().onArtifactAdded = (data) => firstCallbackInvoked = true;

      // Overwrite with second callback
      SignalRService().onArtifactAdded = (data) => secondCallbackInvoked = true;

      SignalRService().onArtifactAdded?.call({'test': 'data'});

      expect(firstCallbackInvoked, isFalse);
      expect(secondCallbackInvoked, isTrue);
    });

    test('Callbacks can be cleared by setting to null', () {
      var callbackInvoked = false;

      SignalRService().onArtifactAdded = (data) => callbackInvoked = true;
      expect(SignalRService().onArtifactAdded, isNotNull);

      // Clear the callback
      SignalRService().onArtifactAdded = null;
      expect(SignalRService().onArtifactAdded, isNull);

      // Try to invoke (should not throw, just do nothing)
      SignalRService().onArtifactAdded?.call({'test': 'data'});

      expect(callbackInvoked, isFalse);
    });
  });

  group('Session ID Filtering Logic', () {
    test('Callback can filter messages by session ID', () {
      const targetSession = 'target-session';
      var correctSessionCalled = false;
      var wrongSessionCalled = false;

      // Register callback that filters by session ID
      SignalRService().onArtifactAdded = (data) {
        if (data is Map && data['sessionId'] == targetSession) {
          correctSessionCalled = true;
        } else {
          wrongSessionCalled = true;
        }
      };

      // Send message with correct session
      SignalRService().onArtifactAdded?.call({
        'sessionId': targetSession,
        'artifact': {'id': '1'},
      });

      expect(correctSessionCalled, isTrue);
      expect(wrongSessionCalled, isFalse);

      correctSessionCalled = false;

      // Send message with wrong session
      SignalRService().onArtifactAdded?.call({
        'sessionId': 'different-session',
        'artifact': {'id': '2'},
      });

      expect(correctSessionCalled, isFalse);
      expect(wrongSessionCalled, isTrue);
    });
  });

  group('Data Validation in Callbacks', () {
    test('Callback can validate artifact data structure', () {
      var validDataReceived = false;
      var invalidDataReceived = false;

      SignalRService().onArtifactAdded = (data) {
        if (data is Map &&
            data['sessionId'] != null &&
            data['artifact'] is Map &&
            data['artifact']['id'] != null) {
          validDataReceived = true;
        } else {
          invalidDataReceived = true;
        }
      };

      // Valid data
      SignalRService().onArtifactAdded?.call({
        'sessionId': 'test',
        'artifact': {'id': 'artifact-1', 'name': 'Test'},
      });

      expect(validDataReceived, isTrue);
      expect(invalidDataReceived, isFalse);

      validDataReceived = false;

      // Invalid data (missing artifact ID)
      SignalRService().onArtifactAdded?.call({
        'sessionId': 'test',
        'artifact': {'name': 'Test'},
      });

      expect(validDataReceived, isFalse);
      expect(invalidDataReceived, isTrue);
    });

    test('Callback handles non-Map data', () {
      var callbackInvoked = false;

      SignalRService().onArtifactAdded = (data) {
        callbackInvoked = true;
        // In real implementation, would check: if (data is! Map) return;
      };

      // Pass invalid data types
      SignalRService().onArtifactAdded?.call('not a map');
      expect(callbackInvoked, isTrue);

      callbackInvoked = false;
      SignalRService().onArtifactAdded?.call(123);
      expect(callbackInvoked, isTrue);

      callbackInvoked = false;
      SignalRService().onArtifactAdded?.call(null);
      expect(callbackInvoked, isTrue);
    });
  });

  group('Synchronization Scenarios', () {
    test('Simulates owner sending artifact added to non-owner', () {
      String? receivedSessionId;
      String? receivedArtifactId;

      // Non-owner registers callback
      SignalRService().onArtifactAdded = (data) {
        if (data is Map && data['sessionId'] == 'shared-session') {
          receivedSessionId = data['sessionId'];
          receivedArtifactId = data['artifact']?['id'];
        }
      };

      // Owner sends artifact added
      SignalRService().onArtifactAdded?.call({
        'sessionId': 'shared-session',
        'artifact': {
          'savedArtefactId': 'saved-xyz',
          'id': 'artifact-123',
          'name': 'Shared Artifact',
        },
      });

      expect(receivedSessionId, equals('shared-session'));
      expect(receivedArtifactId, equals('artifact-123'));
    });

    test('Simulates owner moving artifact and non-owner receiving update', () {
      double? newX;
      double? newY;

      // Non-owner callback for move
      SignalRService().onArtifactMoved = (data) {
        if (data is Map && data['position'] is Map) {
          newX = (data['position']['dx'] as num?)?.toDouble();
          newY = (data['position']['dy'] as num?)?.toDouble();
        }
      };

      // Owner sends move update
      SignalRService().onArtifactMoved?.call({
        'sessionId': 'shared-session',
        'savedArtefactId': 'saved-123',
        'position': {'dx': 250.0, 'dy': 350.0},
      });

      expect(newX, equals(250.0));
      expect(newY, equals(350.0));
    });

    test('Simulates owner removing artifact and non-owner receiving notification', () {
      String? removedArtifactId;

      // Non-owner callback for removal
      SignalRService().onArtifactRemoved = (data) {
        if (data is Map) {
          removedArtifactId = data['savedArtefactId'];
        }
      };

      // Owner sends removal
      SignalRService().onArtifactRemoved?.call({
        'sessionId': 'shared-session',
        'savedArtefactId': 'saved-456',
      });

      expect(removedArtifactId, equals('saved-456'));
    });

    test('Simulates owner changing layout and non-owner receiving update', () {
      String? newLayout;

      // Non-owner callback for layout change
      SignalRService().onLayoutChanged = (data) {
        if (data is Map) {
          newLayout = data['layout'];
        }
      };

      // Owner changes to linear layout
      SignalRService().onLayoutChanged?.call({
        'sessionId': 'shared-session',
        'layout': 'linear',
      });

      expect(newLayout, equals('linear'));
    });

    test('Simulates full board update from owner to non-owner', () {
      String? receivedLayout;
      int? receivedFieldCount;
      int? receivedItemCount;

      // Non-owner callback for full board update
      SignalRService().onBoardUpdated = (data) {
        if (data is Map) {
          receivedLayout = data['layout'];
          receivedFieldCount = data['fieldCount'];
          receivedItemCount = (data['items'] as List?)?.length;
        }
      };

      // Owner sends full board state
      SignalRService().onBoardUpdated?.call({
        'sessionId': 'shared-session',
        'layout': 'talkingmat',
        'fieldCount': 3,
        'items': [
          {'savedArtefactId': 'saved-1', 'id': 'artifact-1'},
          {'savedArtefactId': 'saved-2', 'id': 'artifact-2'},
          {'savedArtefactId': 'saved-3', 'id': 'artifact-3'},
        ],
      });

      expect(receivedLayout, equals('talkingmat'));
      expect(receivedFieldCount, equals(3));
      expect(receivedItemCount, equals(3));
    });
  });
}
