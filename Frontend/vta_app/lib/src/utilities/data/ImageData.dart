// ignore_for_file: file_names

import 'dart:typed_data';

class ImageData {
  final Uint8List bytes;
  final String? name;
  final String extension;

  ImageData({required this.bytes, required this.extension, this.name});
}
