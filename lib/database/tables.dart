/// Định nghĩa cấu trúc Schema các bảng dữ liệu theo chuẩn Database Layer & Supabase Cloud
/// Bao gồm 4 bảng quan hệ cốt lõi: Users, Subjects, Documents, và Permissions cùng RLS Policies.
class UsersTable {
  static const String tableName = 'users';

  static const String columnUid = 'uid';
  static const String columnEmail = 'email';
  static const String columnDisplayName = 'display_name';
  static const String columnPhotoUrl = 'photo_url';
  static const String columnRoleTitle = 'role_title';
  static const String columnDepartment = 'department';
  static const String columnCreatedAt = 'created_at';
  static const String columnLastLoginAt = 'last_login_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnUid TEXT PRIMARY KEY,
      $columnEmail TEXT UNIQUE NOT NULL,
      $columnDisplayName TEXT NOT NULL,
      $columnPhotoUrl TEXT DEFAULT '',
      $columnRoleTitle TEXT DEFAULT 'Sinh viên',
      $columnDepartment TEXT DEFAULT 'Khoa CNTT',
      $columnCreatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      $columnLastLoginAt TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  ''';
}

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
  static const String columnOwnerUid = 'owner_uid';
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
      $columnOwnerUid TEXT REFERENCES ${UsersTable.tableName}(${UsersTable.columnUid}) ON DELETE SET NULL,
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
  static const String columnOwnerUid = 'owner_uid';
  static const String columnType = 'type';
  static const String columnStatus = 'status';
  static const String columnPriority = 'priority';
  static const String columnFileUrl = 'file_url';
  static const String columnStoragePath = 'storage_path';
  static const String columnFileName = 'file_name';
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
      $columnOwnerUid TEXT NOT NULL REFERENCES ${UsersTable.tableName}(${UsersTable.columnUid}) ON DELETE CASCADE,
      $columnType TEXT NOT NULL,
      $columnStatus TEXT NOT NULL,
      $columnPriority TEXT NOT NULL,
      $columnFileUrl TEXT,
      $columnStoragePath TEXT DEFAULT '',
      $columnFileName TEXT DEFAULT '',
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

class PermissionsTable {
  static const String tableName = 'permissions';

  static const String columnId = 'id';
  static const String columnDocumentId = 'document_id';
  static const String columnSharedWithUid = 'shared_with_uid';
  static const String columnSharedWithEmail = 'shared_with_email';
  static const String columnPermissionLevel = 'permission_level'; // 'viewer' | 'editor'
  static const String columnGrantedByUid = 'granted_by_uid';
  static const String columnCreatedAt = 'created_at';
  static const String columnUpdatedAt = 'updated_at';

  static const String createTableSql = '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $columnId TEXT PRIMARY KEY,
      $columnDocumentId TEXT NOT NULL REFERENCES ${DocumentsTable.tableName}(${DocumentsTable.columnId}) ON DELETE CASCADE,
      $columnSharedWithUid TEXT NOT NULL REFERENCES ${UsersTable.tableName}(${UsersTable.columnUid}) ON DELETE CASCADE,
      $columnSharedWithEmail TEXT NOT NULL,
      $columnPermissionLevel TEXT NOT NULL CHECK ($columnPermissionLevel IN ('viewer', 'editor')),
      $columnGrantedByUid TEXT NOT NULL REFERENCES ${UsersTable.tableName}(${UsersTable.columnUid}) ON DELETE CASCADE,
      $columnCreatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      $columnUpdatedAt TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE ($columnDocumentId, $columnSharedWithUid)
    );
  ''';
}
