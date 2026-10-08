import 'dart:typed_data';

/// ImageData class to encapsulate image data, including bytes, name, and extension.
class ImageData {
  final Uint8List bytes;
  final String? name;
  final String extension;

  ImageData({required this.bytes, required this.extension, this.name});
}
