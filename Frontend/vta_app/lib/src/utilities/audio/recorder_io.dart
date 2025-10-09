// Create a recorder implementation for Android/iOS platforms.
// Using the public API with AudioRecorder which is the concrete implementation in v6.x
import 'package:record/record.dart';

dynamic createRecorder() {
  try {
    // In record 6.x, use AudioRecorder which is the concrete implementation
    return AudioRecorder();
  } catch (e) {
    // If instantiation fails, return null and the UI will show appropriate message
    return null;
  }
}
