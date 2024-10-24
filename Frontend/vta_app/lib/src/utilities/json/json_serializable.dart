abstract class JsonSerializable {
  factory JsonSerializable.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented in subclasses');
  }
  Map<String, dynamic> toJson();
}
