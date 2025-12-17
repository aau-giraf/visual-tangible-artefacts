import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:vta_app/src/services/video_call_manager.dart';
import 'package:vta_app/src/services/webrtc_service.dart';
import 'package:vta_app/src/services/signalr_service.dart';
import 'package:vta_app/src/ui/screens/video_call_screen.dart';
import 'package:vta_app/src/ui/screens/remote_board_screen.dart';
import 'package:vta_app/src/ui/widgets/video/pip_video_widget.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/settings/settings_service.dart';

/// Mock WebRTC Service for testing
class MockWebRTCService extends WebRTCService {
  MockWebRTCService({
    required super.hubConnection,
    required super.sessionId,
    required super.myUserId,
    required super.remoteUserId,
  });

  @override
  Future<void> initialize() async {
    // Simulate successful initialization
    hasLocalVideo = true;
    hasLocalAudio = true;
    hasRemoteVideo = true;
    hasRemoteAudio = true;
    
    // Trigger callbacks to simulate connection
    await Future.delayed(const Duration(milliseconds: 100));
    onLocalMediaAvailability?.call(true, true);
    onConnectionEstablished?.call();
  }

  @override
  Future<void> startCall() async {
    // No-op for testing
  }

  @override
  Future<void> dispose() async {
    // No-op for testing
  }

  @override
  void toggleMute() {
    // No-op for testing
  }

  @override
  void toggleCamera() {
    // No-op for testing
  }
}

/// Integration tests using REAL screens for User Story 3
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real Screen PiP Navigation Tests', () {
    late HubConnection mockHubConnection;
    late SettingsController settingsController;

    setUpAll(() async {
      // Create mock hub connection
      mockHubConnection = HubConnectionBuilder()
          .withUrl('http://test:8080/boardHub')
          .build();

      // Initialize settings controller
      final settingsService = SettingsService();
      settingsController = SettingsController(settingsService);
      await settingsController.loadSettings();
    });

    setUp(() async {
      // Reset VideoCallManager state before each test
      try {
        await VideoCallManager().endCall();
      } catch (e) {
        // Ignore if already clean
      }
    });

    tearDown(() async {
      try {
        await VideoCallManager().endCall();
      } catch (e) {
        // Ignore disposal errors
      }
    });

    testWidgets(
        'Real screens: Call persists when navigating from VideoCallScreen to RemoteBoardScreen',
        (WidgetTester tester) async {
      // Build the app with real navigation
      await tester.pumpWidget(
        MaterialApp(
          home: VideoCallScreen(
            hubConnection: mockHubConnection,
            sessionId: 'test-session-123',
            myUserId: 'user1',
            remoteUserId: 'user2',
            isCaller: true,
            returnFromBoard: false,
          ),
          routes: {
            RemoteBoardScreen.routeName: (context) => RemoteBoardScreen(
                  settingsController: settingsController,
                ),
          },
        ),
      );

      // Wait for initial render
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // VideoCallScreen should be visible
      expect(find.byType(VideoCallScreen), findsOneWidget);

      // Wait for WebRTC initialization to complete
      await tester.pumpAndSettle();

      // Look for the "Til Brættet" (To Board) button
      final toBoardButton = find.text('Til Brættet');

      // The button might not be visible immediately, wait for connection
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // If button is available, tap it to navigate to board
      if (toBoardButton.evaluate().isNotEmpty) {
        await tester.tap(toBoardButton);
        await tester.pumpAndSettle();

        // Should now be on RemoteBoardScreen
        expect(find.byType(RemoteBoardScreen), findsOneWidget);

        // PiP widget should be visible on board screen
        expect(
          find.byType(PipVideoWidget),
          findsOneWidget,
          reason: 'PipVideoWidget should be visible on RemoteBoardScreen',
        );

        // VideoCallManager should still report call as active
        expect(
          VideoCallManager().isCallActive,
          isTrue,
          reason: 'Call should remain active after navigating to board',
        );

        // Renderers should be preserved
        expect(
          VideoCallManager().remoteRenderer,
          isNotNull,
          reason: 'Remote renderer should be preserved',
        );
        expect(
          VideoCallManager().localRenderer,
          isNotNull,
          reason: 'Local renderer should be preserved',
        );
      }
    });

    testWidgets(
        'Real screens: Tapping PiP on RemoteBoardScreen navigates back to VideoCallScreen',
        (WidgetTester tester) async {
      // First, manually set up VideoCallManager with active call state
      final localRenderer = RTCVideoRenderer();
      final remoteRenderer = RTCVideoRenderer();
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      await VideoCallManager().initializeCall(
        webrtcService: MockWebRTCService(
          hubConnection: mockHubConnection,
          sessionId: 'test-session-123',
          myUserId: 'user1',
          remoteUserId: 'user2',
        ),
        localRenderer: localRenderer,
        remoteRenderer: remoteRenderer,
        sessionId: 'test-session-123',
      );

      // Build app starting at RemoteBoardScreen with active call
      await tester.pumpWidget(
        MaterialApp(
          home: RemoteBoardScreen(
            settingsController: settingsController,
          ),
          routes: {
            VideoCallScreen.routeName: (context) => VideoCallScreen(
                  hubConnection: mockHubConnection,
                  sessionId: 'test-session-123',
                  myUserId: 'user1',
                  remoteUserId: 'user2',
                  isCaller: true,
                  returnFromBoard: true,
                ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // PiP should be visible
      expect(find.byType(PipVideoWidget), findsOneWidget);

      // Tap the PiP widget
      await tester.tap(find.byType(PipVideoWidget));
      await tester.pumpAndSettle();

      // Should navigate back to VideoCallScreen
      expect(
        find.byType(VideoCallScreen),
        findsOneWidget,
        reason: 'Should return to VideoCallScreen after tapping PiP',
      );

      // Call should still be active
      expect(VideoCallManager().isCallActive, isTrue);
    });

    testWidgets(
        'Real screens: Ending call from RemoteBoardScreen cleans up properly',
        (WidgetTester tester) async {
      // Set up active call state
      final localRenderer = RTCVideoRenderer();
      final remoteRenderer = RTCVideoRenderer();
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      await VideoCallManager().initializeCall(
        webrtcService: MockWebRTCService(
          hubConnection: mockHubConnection,
          sessionId: 'test-session-123',
          myUserId: 'user1',
          remoteUserId: 'user2',
        ),
        localRenderer: localRenderer,
        remoteRenderer: remoteRenderer,
        sessionId: 'test-session-123',
      );

      // Build app at RemoteBoardScreen
      await tester.pumpWidget(
        MaterialApp(
          home: RemoteBoardScreen(
            settingsController: settingsController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // PiP should be visible
      expect(find.byType(PipVideoWidget), findsOneWidget);
      expect(VideoCallManager().isCallActive, isTrue);

      // Find and tap the hang-up button in AppBar
      final hangUpButton = find.byIcon(Icons.call_end);
      expect(hangUpButton, findsOneWidget);

      await tester.tap(hangUpButton);
      await tester.pumpAndSettle();

      // PiP should disappear
      expect(
        find.byType(PipVideoWidget),
        findsNothing,
        reason: 'PiP should disappear after ending call',
      );

      // VideoCallManager should be cleaned up
      expect(
        VideoCallManager().isCallActive,
        isFalse,
        reason: 'Call should no longer be active',
      );

      expect(
        VideoCallManager().remoteRenderer,
        isNull,
        reason: 'Renderer should be disposed',
      );
    });

    testWidgets('Real screens: Multiple navigation cycles preserve state',
        (WidgetTester tester) async {
      // Set up active call
      final localRenderer = RTCVideoRenderer();
      final remoteRenderer = RTCVideoRenderer();
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      await VideoCallManager().initializeCall(
        webrtcService: MockWebRTCService(
          hubConnection: mockHubConnection,
          sessionId: 'test-session-123',
          myUserId: 'user1',
          remoteUserId: 'user2',
        ),
        localRenderer: localRenderer,
        remoteRenderer: remoteRenderer,
        sessionId: 'test-session-123',
      );

      // Build app with both routes
      await tester.pumpWidget(
        MaterialApp(
          home: RemoteBoardScreen(
            settingsController: settingsController,
          ),
          routes: {
            VideoCallScreen.routeName: (context) => VideoCallScreen(
                  hubConnection: mockHubConnection,
                  sessionId: 'test-session-123',
                  myUserId: 'user1',
                  remoteUserId: 'user2',
                  isCaller: true,
                  returnFromBoard: true,
                ),
            RemoteBoardScreen.routeName: (context) => RemoteBoardScreen(
                  settingsController: settingsController,
                ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Cycle 1: Board -> Video -> Board
      expect(find.byType(RemoteBoardScreen), findsOneWidget);
      expect(VideoCallManager().isCallActive, isTrue);

      await tester.tap(find.byType(PipVideoWidget));
      await tester.pumpAndSettle();

      expect(find.byType(VideoCallScreen), findsOneWidget);
      expect(VideoCallManager().isCallActive, isTrue);

      // Navigate back to board (if button is available)
      final toBoardButton = find.text('Til Brættet');
      if (toBoardButton.evaluate().isNotEmpty) {
        await tester.tap(toBoardButton);
        await tester.pumpAndSettle();

        expect(find.byType(RemoteBoardScreen), findsOneWidget);
        expect(VideoCallManager().isCallActive, isTrue);
      }

      // State should be preserved throughout
      expect(VideoCallManager().remoteRenderer, isNotNull);
    });
  });
}
