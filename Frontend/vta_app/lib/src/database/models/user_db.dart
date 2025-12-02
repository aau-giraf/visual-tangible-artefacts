/// SQLite database model for the user table.
class UserDB {
  final String id;
  final String? name;
  final String? username;
  final int nameVisible;
  final int fieldCount;
  final int? modifiedDate;
  final int isDeleted;

  UserDB({
    required this.id,
    this.name,
    this.username,
    required this.nameVisible,
    required this.fieldCount,
    this.modifiedDate,
    this.isDeleted = 0,
  });

  /// Converts the UserDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'name_visible': nameVisible,
      'field_count': fieldCount,
      'modified_date': modifiedDate,
      'is_deleted': isDeleted,
    };
  }

  /// Creates a UserDB object from a database Map.
  factory UserDB.fromMap(Map<String, dynamic> map) {
    return UserDB(
      id: map['id'] as String,
      name: map['name'] as String?,
      username: map['username'] as String?,
      nameVisible: map['name_visible'] as int,
      fieldCount: map['field_count'] as int,
      modifiedDate: map['modified_date'] as int?,
      isDeleted: map['is_deleted'] as int,
    );
  }

  /// Creates a copy of this UserDB with the given fields replaced.
  UserDB copyWith({
    String? id,
    String? name,
    String? username,
    int? nameVisible,
    int? fieldCount,
    int? modifiedDate,
    int? isDeleted,
  }) {
    return UserDB(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      nameVisible: nameVisible ?? this.nameVisible,
      fieldCount: fieldCount ?? this.fieldCount,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'UserDB{id: $id, name: $name, username: $username, nameVisible: $nameVisible, fieldCount: $fieldCount, modifiedDate: $modifiedDate, isDeleted: $isDeleted}';
  }
}
