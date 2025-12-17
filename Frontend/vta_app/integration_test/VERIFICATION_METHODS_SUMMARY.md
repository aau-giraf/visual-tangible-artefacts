# Verification Methods Summary for Thesis

## Table Content for Sprint 4 - Real-time Voice and Video Communication

### User Story 1: See and hear other participant
**User Story:** As a user, I want to see and hear the other participant during a remote session.

**Acceptance Criteria:** Audio and video streams are established between participants; both feeds are visible and audible.

**Verification Method:** Manual testing protocol with device/browser matrix (Chrome, Firefox, Safari on Windows, macOS, iOS, Android). Test cases cover all media combinations (video+audio, video-only, audio-only). Verify visual indicators ("Ingen lyd", "Kamera utilgængeligt"), audio quality through user confirmation, RTCVideoView rendering, and connection stability. Document results for each platform combination.

**Rationale:** Audio playback quality and video rendering cannot be reliably verified programmatically. WebRTC depends on browser permissions, real hardware, and network conditions. Automated tests would require extensive mocking without catching real integration issues, making manual testing more cost-effective.

---

### User Story 2: Asymmetric media configurations
**User Story:** As a user, I want the call to continue working even if I only have a microphone or only have a camera available.

**Acceptance Criteria:** Call establishes successfully with asymmetric media configurations (audio-only, video-only, or both).

**Verification Method:** Semi-automated approach combining Patrol integration tests with manual verification. Automated tests (`asymmetric_media_test.dart`) verify UI state for 6 media configurations: local/remote audio/video unavailable, audio-only calls, and no local media. Tests validate correct indicators shown, control buttons enabled/disabled appropriately, and graceful degradation logic. Manual testing verifies actual media transmission on real hardware with permission scenarios.

**Rationale:** UI state logic and fallback behavior are reliably testable through automation, providing regression protection. However, actual media transmission quality requires manual verification. This hybrid approach maximizes automation value while ensuring real-world functionality.

**Test File:** `integration_test/asymmetric_media_test.dart` (6 test cases)

---

### User Story 3: Picture-in-Picture during navigation
**User Story:** As a user, I want to navigate to the board while maintaining the active call.

**Acceptance Criteria:** Call persists when navigating away from the call screen; video displays in picture-in-picture mode.

**Verification Method:** Automated Patrol integration tests (`pip_navigation_test.dart`) verify: (1) Call state persists across navigation using VideoCallManager singleton, (2) PipVideoWidget renders correctly on board screen, (3) Tapping PiP returns to full video with state restoration, (4) PiP widget is draggable, (5) Ending call from board properly cleans up resources, (6) PiP displays correct indicators for audio-only streams, (7) Multiple navigation cycles preserve state integrity.

**Rationale:** This functionality is entirely UI state and navigation logic—no real media required. Automated testing provides high value for complex state management, prevents regressions, and efficiently verifies renderer lifecycle management. This is where integration tests excel compared to manual testing.

**Test File:** `integration_test/pip_navigation_test.dart` (7 test cases)

---

## Test Execution Commands

### Run all integration tests
```bash
patrol test
```

### Run specific test suites
```bash
# User Story 2 tests
patrol test integration_test/asymmetric_media_test.dart

# User Story 3 tests  
patrol test integration_test/pip_navigation_test.dart
```

### Run on specific platform
```bash
patrol test -d android
patrol test -d ios
```

---

## Test Coverage Summary

| Aspect | Automated | Manual | Rationale |
|--------|-----------|--------|-----------|
| Audio/video quality | ❌ | ✅ | Cannot verify media quality programmatically |
| UI indicators | ✅ | ✅ | Automated for regression, manual for real devices |
| Control button states | ✅ | ⚠️ | Fully automated with mocked media |
| Graceful degradation | ✅ | ✅ | Logic automated, actual fallback manual |
| PiP visibility | ✅ | ❌ | Pure UI state, ideal for automation |
| State persistence | ✅ | ❌ | Complex state management, automated |
| Navigation flow | ✅ | ❌ | UI navigation, fully automated |
| Resource cleanup | ✅ | ❌ | Renderer lifecycle, automated |

**Total Test Cases:** 13 automated + structured manual protocol

---

## Integration with Development Workflow

The automated tests run in CI/CD pipeline on every commit, providing immediate feedback on:
- UI regression in media indicators
- State management bugs in navigation
- Renderer lifecycle issues
- PiP functionality breaking changes

Manual tests are performed:
- Before releases
- When adding new device/platform support
- When WebRTC dependencies are updated
- During user acceptance testing
