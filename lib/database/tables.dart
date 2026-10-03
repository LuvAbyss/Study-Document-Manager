/// Định nghĩa cấu trúc Schema các bảng dữ liệu theo chuẩn Database Layer
/// Tương ứng với cách Cashew định nghĩa các bảng Drift/SQLite
class SubjectsTable {
  static const String tableName = 'subjects';

  static const String columnId = 'id';
  static const String columnCode = 'code';
  static const String columnName = 'name';
  static const String columnLecturer = 'lecturer';
  static const String columnColorValue = 'color_value';
  static const String columnIconName = 'icon_name';
  static const String columnSemester = 'semester';
  static const String columnCreditCount = 'credit_count';
  static const String columnCreatedAt = 'created_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnCode TEXT NOT NULL,
      $columnName TEXT NOT NULL,
      $columnLecturer TEXT,
      $columnColorValue INTEGER NOT NULL DEFAULT 4280193253,
      $columnIconName TEXT NOT NULL DEFAULT 'book',
      $columnSemester TEXT NOT NULL DEFAULT 'HK1 2026-2027',
      $columnCreditCount INTEGER NOT NULL DEFAULT 3,
      $columnCreatedAt TEXT NOT NULL
    );
  ''';
}

class DocumentsTable {
  static const String tableName = 'documents';

  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnSubjectId = 'subject_id';
  static const String columnType = 'type';
  static const String columnStatus = 'status';
  static const String columnPriority = 'priority';
  static const String columnFileUrl = 'file_url';
  static const String columnFileType = 'file_type';
  static const String columnFileSizeBytes = 'file_size_bytes';
  static const String columnDueDate = 'due_date';
  static const String columnIsFavorite = 'is_favorite';
  static const String columnTags = 'tags';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnTitle TEXT NOT NULL,
      $columnDescription TEXT,
      $columnSubjectId TEXT NOT NULL,
      $columnType TEXT NOT NULL,
      $columnStatus TEXT NOT NULL,
      $columnPriority TEXT NOT NULL,
      $columnFileUrl TEXT,
      $columnFileType TEXT NOT NULL DEFAULT 'PDF',
      $columnFileSizeBytes INTEGER NOT NULL DEFAULT 0,
      $columnDueDate TEXT,
      $columnIsFavorite INTEGER NOT NULL DEFAULT 0,
      $columnTags TEXT,
      $columnCreatedAt TEXT NOT NULL,
      $columnUpdatedAt TEXT NOT NULL,
      FOREIGN KEY ($columnSubjectId) REFERENCES ${SubjectsTable.tableName} (${SubjectsTable.columnId}) ON DELETE CASCADE
    );
  ''';
}
