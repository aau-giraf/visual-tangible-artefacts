# WebRTC Integration Tests

This directory contains Patrol integration tests for WebRTC video call functionality.

## Test Files

### 1. `asymmetric_media_test.dart` (User Story 2)
Tests UI behavior when calls establish with different media configurations:
- ✅ Local audio unavailable (microphone disabled)
- ✅ Local video unavailable (camera disabled)
- ✅ Remote audio unavailable
- ✅ Remote video unavailable
- ✅ Audio-only calls
- ✅ No local media available

**What it tests:**
- Correct indicators shown ("Ingen mikrofon", "Ingen lyd", "Kamera utilgængeligt")
- Control buttons are enabled/disabled appropriately
- Placeholder icons shown when video unavailable
- UI gracefully handles all media combinations

### 2. `pip_navigation_test.dart` (User Story 3)
Tests Picture-in-Picture functionality during navigation:
- ✅ Call persists when navigating to board screen
- ✅ PiP widget is visible on board screen
- ✅ Tapping PiP returns to full video call
- ✅ PiP widget is draggable
- ✅ Ending call cleans up properly
- ✅ PiP shows correct indicators for audio-only streams
- ✅ Multiple navigation cycles work correctly

**What it tests:**
- VideoCallManager state persistence
- Renderer lifecycle management
- PiP widget visibility and interactions
- Navigation flow integrity
- Proper cleanup on call end

## Prerequisites

1. **Patrol CLI installed:**
   ```bash
   dart pub global activate patrol_cli
   ```

2. **Flutter dependencies installed:**
   ```bash
   flutter pub get
   ```

3. **Environment configured:**
   - For Android: Android emulator running or device connected
   - For iOS: iOS simulator running or device connected
   - For Web: Chrome browser available

## Running the Tests

### Run All Integration Tests
```bash
patrol test
```

### Run Specific Test File
```bash
# Asymmetric media configuration tests
patrol test integration_test/asymmetric_media_test.dart

# PiP navigation tests
patrol test integration_test/pip_navigation_test.dart
```

### Run on Specific Platform
```bash
# Android
patrol test -d android

# iOS
patrol test -d ios

# Web (limited support for WebRTC mocking)
patrol test -d chrome
```

### Run with Verbose Output
```bash
patrol test --verbose
```

### Run in Debug Mode
```bash
patrol test --debug
```

## Understanding Test Results

### Expected Output
```
✓ UI shows correct indicators when local audio is unavailable
✓ UI shows correct indicators when local video is unavailable
✓ UI shows correct indicators when remote audio is unavailable
✓ UI shows correct state when remote video is unavailable
✓ UI handles audio-only call correctly
✓ UI handles no local media gracefully

✓ Video call persists when navigating to board screen
✓ Tapping PiP widget returns to full video call screen
✓ PiP video widget is draggable on board screen
✓ Ending call from board screen cleans up properly
✓ PiP shows correct indicators for audio-only remote stream
✓ PiP shows no audio indicator when remote has no audio
✓ Multiple navigation cycles preserve call state
```

### Common Issues

**Issue: Tests timeout**
- Increase timeout in test: `timeout: const Duration(seconds: 10)`
- Check that emulator/simulator is responsive
- Ensure `pumpAndSettle()` is used after navigation

**Issue: Widget not found**
- Verify widget keys and text match exactly (Danish text: "Ingen lyd", "Kamera utilgængeligt")
- Use `$.waitUntilVisible()` for async rendering
- Check that widget is actually rendered (not hidden by conditional logic)

**Issue: WebRTC permissions**
- Android: Ensure permissions in AndroidManifest.xml
- iOS: Ensure permissions in Info.plist
- Web: Browser may block media access in headless mode

**Issue: State not preserved**
- Verify VideoCallManager singleton is working
- Check dispose methods aren't being called prematurely
- Ensure `_hasTransitioned` flag logic is correct

## Test Maintenance

### When to Update Tests

1. **UI Text Changes:** If Danish strings change, update test expectations
2. **New Indicators:** Add new test cases for new UI indicators
3. **Navigation Changes:** Update navigation flow if routes change
4. **New Media States:** Add tests for new media configuration scenarios

### Test Coverage

Current coverage:
- ✅ All 6 media configuration combinations (Story 2)
- ✅ Full PiP lifecycle (Story 3)
- ✅ State management across navigation (Story 3)
- ⚠️ **Not covered:** Actual media transmission (requires manual testing)
- ⚠️ **Not covered:** Real WebRTC connection establishment (requires manual testing)

## Integration with CI/CD

### GitHub Actions Example
```yaml
name: Integration Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: dart pub global activate patrol_cli
      - run: patrol test --dart-define=CI=true
```

### Local Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit
patrol test integration_test/asymmetric_media_test.dart
patrol test integration_test/pip_navigation_test.dart
```

## Debugging Tests

### Enable Verbose Logging
```dart
// Add to test file
setUp(() {
  debugPrint('=== TEST SETUP ===');
});

tearDown(() {
  debugPrint('=== TEST TEARDOWN ===');
});
```

### Take Screenshots on Failure
```dart
patrolTest('my test', ($) async {
  try {
    // test code
  } catch (e) {
    await $.native.takeScreenshot('failure_screenshot');
    rethrow;
  }
});
```

### Inspect Widget Tree
```bash
# Add to test
debugDumpApp();
```

## Related Documentation

- [Patrol Documentation](https://patrol.leancode.co/)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [flutter_webrtc Package](https://pub.dev/packages/flutter_webrtc)

## Contributing

When adding new tests:
1. Follow existing naming conventions
2. Add descriptive test names
3. Include `reason` parameter in assertions
4. Update this README with new test descriptions
5. Ensure tests are idempotent (can run multiple times)
