/// SQLite database model for the category table.
class CategoryDB {
  final String categoryId;
  final int? categoryIndex;
  final String userId;
  final String? name;
  final String? imagePath;
  final int? modifiedDate;
  final int usageCount;
  final int? lastUsedDate;
  final int isDeleted;

  CategoryDB({
    required this.categoryId,
    this.categoryIndex,
    required this.userId,
    this.name,
    this.imagePath,
    this.modifiedDate,
    this.usageCount = 0,
    this.lastUsedDate,
    this.isDeleted = 0,
  });

  /// Converts the CategoryDB object to a Map for database operations.
  Map<String, dynamic> toMap() {
    return {
      'category_id': categoryId,
      'category_index': categoryIndex,
      'user_id': userId,
      'name': name,
      'image_path': imagePath,
      'modified_date': modifiedDate,
      'usage_count': usageCount,
      'last_used_date': lastUsedDate,
      'is_deleted': isDeleted,
    };
  }

  /// Creates a CategoryDB object from a database Map.
  factory CategoryDB.fromMap(Map<String, dynamic> map) {
    return CategoryDB(
      categoryId: map['category_id'] as String,
      categoryIndex: map['category_index'] as int?,
      userId: map['user_id'] as String,
      name: map['name'] as String?,
      imagePath: map['image_path'] as String?,
      modifiedDate: map['modified_date'] as int?,
      usageCount: map['usage_count'] as int? ?? 0,
      lastUsedDate: map['last_used_date'] as int?,
      isDeleted: map['is_deleted'] as int? ?? 0,
    );
  }

  /// Creates a copy of this CategoryDB with the given fields replaced.
  CategoryDB copyWith({
    String? categoryId,
    int? categoryIndex,
    String? userId,
    String? name,
    String? imagePath,
    int? modifiedDate,
    int? usageCount,
    int? lastUsedDate,
    int? isDeleted,
  }) {
    return CategoryDB(
      categoryId: categoryId ?? this.categoryId,
      categoryIndex: categoryIndex ?? this.categoryIndex,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      usageCount: usageCount ?? this.usageCount,
      lastUsedDate: lastUsedDate ?? this.lastUsedDate,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  String toString() {
    return 'CategoryDB{categoryId: $categoryId, categoryIndex: $categoryIndex, userId: $userId, name: $name, imagePath: $imagePath, modifiedDate: $modifiedDate, usageCount: $usageCount, lastUsedDate: $lastUsedDate, isDeleted: $isDeleted}';
  }
}
