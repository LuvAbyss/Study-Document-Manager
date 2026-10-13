import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/tables.dart';
import '../struct/models.dart';
import 'cloud_config.dart';

/// Dịch vụ Đồng bộ Cơ sở Dữ liệu Quan hệ trên Supabase (PostgreSQL + RLS)
/// Quản lý 3 bảng trọng tâm: `users`, `documents`, và `permissions`
class SupabaseSyncService {
  static final SupabaseSyncService instance = SupabaseSyncService();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo kết nối Supabase Client
  Future<void> initializeIfConfigured() async {
    if (_isInitialized || !CloudConfig.hasLiveSupabaseKeys) return;
    try {
      await Supabase.initialize(
        url: CloudConfig.supabaseUrl,
        publishableKey: CloudConfig.supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  SupabaseClient? get _client =>
      _isInitialized ? Supabase.instance.client : null;

  /// Đồng bộ thông tin người dùng Google vào bảng `users` trên Supabase
  Future<void> upsertUserToSupabase(AppUser user) async {
    final client = _client;
    if (client == null) return;
    await client.from(UsersTable.tableName).upsert(user.toMap());
  }

  /// Đồng bộ thông tin tài liệu (kèm đường dẫn Firebase Storage) vào bảng `documents` trên Supabase
  Future<void> upsertDocumentToSupabase(StudyDocument doc) async {
    final client = _client;
    if (client == null) return;
    await client.from(DocumentsTable.tableName).upsert({
      DocumentsTable.columnId: doc.id,
      DocumentsTable.columnTitle: doc.title,
      DocumentsTable.columnDescription: doc.description,
      DocumentsTable.columnSubjectId: doc.subjectId,
      DocumentsTable.columnOwnerUid: doc.ownerUid,
      DocumentsTable.columnType: doc.type.name,
      DocumentsTable.columnStatus: doc.status.name,
      DocumentsTable.columnPriority: doc.priority.name,
      DocumentsTable.columnFileUrl: doc.fileUrl,
      DocumentsTable.columnStoragePath: doc.storagePath,
      DocumentsTable.columnFileName: doc.fileName,
      DocumentsTable.columnFileType: doc.fileType,
      DocumentsTable.columnFileSizeBytes: doc.fileSizeBytes,
      DocumentsTable.columnDueDate: doc.dueDate?.toIso8601String(),
      DocumentsTable.columnIsFavorite: doc.isFavorite,
      DocumentsTable.columnTags: doc.tags,
      DocumentsTable.columnCreatedAt: doc.createdAt.toIso8601String(),
      DocumentsTable.columnUpdatedAt: doc.updatedAt.toIso8601String(),
    });
  }

  /// Xóa bản ghi tài liệu trên Supabase (RLS chỉ cho phép owner_uid thực hiện)
  Future<void> deleteDocumentFromSupabase(String documentId) async {
    final client = _client;
    if (client == null) return;
    await client
        .from(DocumentsTable.tableName)
        .delete()
        .eq(DocumentsTable.columnId, documentId);
  }

  /// Đồng bộ bản ghi phân quyền chia sẻ vào bảng `permissions` trên Supabase
  Future<void> upsertPermissionToSupabase(DocumentPermission permission) async {
    final client = _client;
    if (client == null) return;
    await client.from(PermissionsTable.tableName).upsert({
      PermissionsTable.columnId: permission.id,
      PermissionsTable.columnDocumentId: permission.documentId,
      PermissionsTable.columnSharedWithUid: permission.sharedWithUid,
      PermissionsTable.columnSharedWithEmail: permission.sharedWithEmail,
      PermissionsTable.columnPermissionLevel: permission.permissionLevel.name,
      PermissionsTable.columnGrantedByUid: permission.grantedByUid,
      PermissionsTable.columnCreatedAt: permission.createdAt.toIso8601String(),
      PermissionsTable.columnUpdatedAt: permission.updatedAt.toIso8601String(),
    });
  }

  /// Thu hồi quyền chia sẻ trên bảng `permissions` của Supabase
  Future<void> deletePermissionFromSupabase(String permissionId) async {
    final client = _client;
    if (client == null) return;
    await client
        .from(PermissionsTable.tableName)
        .delete()
        .eq(PermissionsTable.columnId, permissionId);
  }
}
