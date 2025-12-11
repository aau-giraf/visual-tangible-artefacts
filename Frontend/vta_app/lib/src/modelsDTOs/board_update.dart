class BoardUpdate {
  final String type;
  final Map<String, dynamic> payload;

  BoardUpdate(this.type, this.payload);

  Map<String, dynamic> toJson() => {
        "type": type,
        "payload": payload,
      };

  factory BoardUpdate.fromJson(Map<String, dynamic> json) {
    return BoardUpdate(
      json["type"] as String,
      Map<String, dynamic>.from(json["payload"]),
    );
  }

  // Optional: Add static factories for common update events
  static BoardUpdate add(Map<String, dynamic> data) => BoardUpdate("add", data);

  static BoardUpdate move(Map<String, dynamic> data) =>
      BoardUpdate("move", data);

  static BoardUpdate remove(String artefactId) =>
      BoardUpdate("delete", {"id": artefactId});

  static BoardUpdate layout(bool isDirectional) =>
      BoardUpdate("layout", {"directional": isDirectional});

  static BoardUpdate fieldCount(int count) =>
      BoardUpdate("fieldCount", {"count": count});
}
