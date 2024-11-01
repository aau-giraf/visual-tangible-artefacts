import 'package:camera/camera.dart';

class CameraManager {
  static final CameraManager _instance = CameraManager._internal();
  List<CameraDescription> _cameras = [];

  factory CameraManager() {
    return _instance;
  }

  CameraManager._internal();

  Future<void> initialize() async {
    _cameras = await availableCameras();
  }

  List<CameraDescription> get cameras => _cameras;

  CameraDescription? get firstCamera =>
      _cameras.isNotEmpty ? _cameras.first : null;
}
