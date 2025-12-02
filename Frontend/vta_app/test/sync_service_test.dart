import 'package:flutter_test/flutter_test.dart';
import 'package:vta_app/src/services/sync_service.dart';

void main() {
  group('FileChangeRecord', () {
    test('creates from artefact JSON correctly', () {
      final json = {
        'artefactId': 'test-123',
        'name': 'Test Artefact',
        'modifiedDate': '2024-11-27T12:00:00Z',
        'imageUrl': 'https://example.com/image.jpg',
        'soundUrl': 'https://example.com/sound.mp3',
      };

      final record = FileChangeRecord.fromArtefact(json);

      expect(record.fileId, equals('test-123'));
      expect(record.fileName, equals('Test Artefact'));
      expect(record.fileType, equals('artefact'));
      expect(record.modifiedDate, isNotNull);
      expect(record.imageUrl, equals('https://example.com/image.jpg'));
      expect(record.soundUrl, equals('https://example.com/sound.mp3'));
    });

    test('creates from artefact JSON with null name', () {
      final json = {
        'artefactId': 'test-123',
        'modifiedDate': '2024-11-27T12:00:00Z',
      };

      final record = FileChangeRecord.fromArtefact(json);

      expect(record.fileName, equals('Unnamed Artefact'));
    });

    test('creates from board JSON correctly', () {
      final json = {
        'boardId': 'board-456',
        'name': 'Test Board',
        'modifiedDate': '2024-11-27T14:00:00Z',
      };

      final record = FileChangeRecord.fromBoard(json);

      expect(record.fileId, equals('board-456'));
      expect(record.fileName, equals('Test Board'));
      expect(record.fileType, equals('board'));
      expect(record.modifiedDate, isNotNull);
      expect(record.imageUrl, isNull);
      expect(record.soundUrl, isNull);
    });

    test('handles null modified date', () {
      final json = {
        'artefactId': 'test-123',
        'name': 'Test',
      };

      final record = FileChangeRecord.fromArtefact(json);

      expect(record.modifiedDate, isNull);
    });

    test('converts to JSON correctly', () {
      final record = FileChangeRecord(
        fileId: 'test-123',
        fileName: 'Test File',
        fileType: 'artefact',
        modifiedDate: DateTime(2024, 11, 27, 12, 0, 0),
        imageUrl: 'https://example.com/image.jpg',
        soundUrl: 'https://example.com/sound.mp3',
      );

      final json = record.toJson();

      expect(json['fileId'], equals('test-123'));
      expect(json['fileName'], equals('Test File'));
      expect(json['fileType'], equals('artefact'));
      expect(json['modifiedDate'], isNotNull);
      expect(json['imageUrl'], equals('https://example.com/image.jpg'));
      expect(json['soundUrl'], equals('https://example.com/sound.mp3'));
    });

    test('toString returns formatted string', () {
      final record = FileChangeRecord(
        fileId: 'test-123',
        fileName: 'Test File',
        fileType: 'artefact',
        modifiedDate: DateTime(2024, 11, 27, 12, 0, 0),
      );

      final str = record.toString();

      expect(str, contains('test-123'));
      expect(str, contains('Test File'));
      expect(str, contains('artefact'));
    });
  });

  group('SyncCheckResponse', () {
    test('creates correctly', () {
      final changes = [
        FileChangeRecord(
          fileId: 'test-1',
          fileName: 'File 1',
          fileType: 'artefact',
          modifiedDate: DateTime(2024, 11, 27),
        ),
        FileChangeRecord(
          fileId: 'test-2',
          fileName: 'File 2',
          fileType: 'board',
          modifiedDate: DateTime(2024, 11, 26),
        ),
      ];

      final response = SyncCheckResponse(
        changedFiles: changes,
        checkDate: DateTime(2024, 11, 27, 15, 0, 0),
        totalChanges: 2,
      );

      expect(response.changedFiles.length, equals(2));
      expect(response.totalChanges, equals(2));
      expect(response.checkDate, isNotNull);
    });

    test('converts to JSON correctly', () {
      final changes = [
        FileChangeRecord(
          fileId: 'test-1',
          fileName: 'File 1',
          fileType: 'artefact',
          modifiedDate: DateTime(2024, 11, 27),
        ),
      ];

      final response = SyncCheckResponse(
        changedFiles: changes,
        checkDate: DateTime(2024, 11, 27, 15, 0, 0),
        totalChanges: 1,
      );

      final json = response.toJson();

      expect(json['totalChanges'], equals(1));
      expect(json['changedFiles'], isA<List>());
      expect(json['checkDate'], isNotNull);
    });

    test('toString returns formatted string', () {
      final response = SyncCheckResponse(
        changedFiles: [],
        checkDate: DateTime(2024, 11, 27, 15, 0, 0),
        totalChanges: 0,
      );

      final str = response.toString();

      expect(str, contains('totalChanges: 0'));
    });
  });

  group('SyncService Integration', () {
    // Note: These tests would require mocking the API provider and token
    // For now, we'll just test that the service can be instantiated
    
    test('can create SyncService instance', () {
      // This will fail without proper setup, but shows the interface
      expect(() => SyncService(), returnsNormally);
    });
  });
}
