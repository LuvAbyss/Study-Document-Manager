import '../struct/models.dart';

/// Ngoại lệ phát sinh khi vi phạm chính sách bảo mật Row Level Security (RLS) trên Supabase
class RlsAccessDeniedException implements Exception {
  final String policyName;
  final String operation;
  final String userUid;
  final String message;

  const RlsAccessDeniedException({
    required this.policyName,
    required this.operation,
    required this.userUid,
    required this.message,
  });

  @override
  String toString() =>
      'RlsAccessDeniedException [$policyName | $operation | uid=$userUid]: $message';
}

/// Bộ thực thi Chính sách Bảo mật Row Level Security (RLS Policy Engine)
/// Phản ánh chính xác 1-1 các chính sách PostgreSQL RLS đã thiết lập trên Supabase
/// trong tệp `supabase/migrations/001_supabase_schema_and_rls.sql`.
class RlsPolicyEngine {
  /// Xác định cấp độ quyền hiệu lực (Effective Permission Level) của một người dùng đối với tài liệu
  static PermissionLevel resolvePermissionLevel({
    required StudyDocument document,
    required Iterable<DocumentPermission> permissions,
    required String? userUid,
  }) {
    if (userUid == null || userUid.trim().isEmpty) {
      return PermissionLevel.none;
    }

    // 1. Nếu là chủ sở hữu (owner_uid == current_user_uid())
    if (document.ownerUid == userUid) {
      return PermissionLevel.owner;
    }

    // 2. Kiểm tra trong bảng permissions xem người dùng có được chia sẻ hay không
    for (final perm in permissions) {
      if (perm.documentId == document.id && perm.sharedWithUid == userUid) {
        return perm.permissionLevel;
      }
    }

    // 3. Mặc định bị chặn bởi RLS
    return PermissionLevel.none;
  }

  /// Chính sách RLS `documents_select_owner_or_shared`:
  /// Chỉ trả về các tài liệu mà user hiện tại là Owner hoặc có bản ghi trong bảng `permissions`
  static List<StudyDocument> filterAccessibleDocuments({
    required Iterable<StudyDocument> allDocuments,
    required Iterable<DocumentPermission> allPermissions,
    required String? currentUserUid,
  }) {
    if (currentUserUid == null || currentUserUid.trim().isEmpty) {
      return const [];
    }

    return allDocuments.where((doc) {
      final level = resolvePermissionLevel(
        document: doc,
        permissions: allPermissions,
        userUid: currentUserUid,
      );
      return level.canView;
    }).toList();
  }

  /// Kiểm tra quyền SELECT trên một tài liệu cụ thể
  static void assertCanSelectDocument({
    required StudyDocument document,
    required Iterable<DocumentPermission> permissions,
    required String? currentUserUid,
  }) {
    final level = resolvePermissionLevel(
      document: document,
      permissions: permissions,
      userUid: currentUserUid,
    );
    if (!level.canView) {
      throw RlsAccessDeniedException(
        policyName: 'documents_select_owner_or_shared',
        operation: 'SELECT',
        userUid: currentUserUid ?? 'anonymous',
        message:
            'Từ chối truy cập (RLS): Bạn không có quyền xem tài liệu "${document.title}".',
      );
    }
  }

  /// Chính sách RLS `documents_insert_owner_only`:
  /// Người dùng đã xác thực chỉ được thêm tài liệu với `owner_uid` là chính mình
  static void assertCanInsertDocument({
    required StudyDocument document,
    required String? currentUserUid,
  }) {
    if (currentUserUid == null || currentUserUid.trim().isEmpty) {
      throw const RlsAccessDeniedException(
        policyName: 'documents_insert_owner_only',
        operation: 'INSERT',
        userUid: 'anonymous',
        message: 'Từ chối truy cập (RLS): Vui lòng đăng nhập Google trước khi tạo tài liệu.',
      );
    }

    if (document.ownerUid != currentUserUid) {
      throw RlsAccessDeniedException(
        policyName: 'documents_insert_owner_only',
        operation: 'INSERT',
        userUid: currentUserUid,
        message:
            'Từ chối truy cập (RLS): Không thể tạo tài liệu mạo danh chủ sở hữu khác (${document.ownerUid}).',
      );
    }
  }

  /// Chính sách RLS `documents_update_owner_or_editor`:
  /// Chỉ Owner hoặc người được chia sẻ quyền `editor` mới được cập nhật thông tin tài liệu.
  /// Đồng thời chặn `editor` thay đổi `owner_uid` (chiếm quyền sở hữu).
  static void assertCanUpdateDocument({
    required StudyDocument existingDocument,
    required StudyDocument updatedDocument,
    required Iterable<DocumentPermission> permissions,
    required String? currentUserUid,
  }) {
    final level = resolvePermissionLevel(
      document: existingDocument,
      permissions: permissions,
      userUid: currentUserUid,
    );

    if (!level.canEdit) {
      throw RlsAccessDeniedException(
        policyName: 'documents_update_owner_or_editor',
        operation: 'UPDATE',
        userUid: currentUserUid ?? 'anonymous',
        message: level == PermissionLevel.viewer
            ? 'Từ chối truy cập (RLS): Tài khoản của bạn chỉ có quyền XEM (Viewer), không được phép chỉnh sửa tài liệu "${existingDocument.title}".'
            : 'Từ chối truy cập (RLS): Bạn không có quyền chỉnh sửa tài liệu "${existingDocument.title}".',
      );
    }

    // Ngăn chặn việc thay đổi ownerUid trái phép
    if (existingDocument.ownerUid != updatedDocument.ownerUid) {
      throw RlsAccessDeniedException(
        policyName: 'documents_update_owner_or_editor',
        operation: 'UPDATE',
        userUid: currentUserUid ?? 'anonymous',
        message:
            'Từ chối truy cập (RLS): Không được phép thay đổi chủ sở hữu gốc (owner_uid) của tài liệu.',
      );
    }
  }

  /// Chính sách RLS `documents_delete_owner_only`:
  /// CHỈ Chủ sở hữu (`owner`) mới có quyền xóa tài liệu (Editor và Viewer đều bị chặn)
  static void assertCanDeleteDocument({
    required StudyDocument document,
    required Iterable<DocumentPermission> permissions,
    required String? currentUserUid,
  }) {
    final level = resolvePermissionLevel(
      document: document,
      permissions: permissions,
      userUid: currentUserUid,
    );

    if (!level.canDelete) {
      throw RlsAccessDeniedException(
        policyName: 'documents_delete_owner_only',
        operation: 'DELETE',
        userUid: currentUserUid ?? 'anonymous',
        message:
            'Từ chối truy cập (RLS): Chỉ Chủ sở hữu (Owner) mới được xóa tài liệu "${document.title}". Quyền hiện tại của bạn: ${level.displayName}.',
      );
    }
  }

  /// Chính sách RLS `permissions_insert_document_owner_only` & `permissions_update_document_owner_only`:
  /// Chỉ Chủ sở hữu tài liệu mới được cấp, sửa hoặc thu hồi quyền chia sẻ
  static void assertCanManagePermissions({
    required StudyDocument document,
    required Iterable<DocumentPermission> permissions,
    required String? currentUserUid,
    String operation = 'SHARE',
  }) {
    final level = resolvePermissionLevel(
      document: document,
      permissions: permissions,
      userUid: currentUserUid,
    );

    if (!level.canManagePermissions) {
      throw RlsAccessDeniedException(
        policyName: 'permissions_insert_document_owner_only',
        operation: operation,
        userUid: currentUserUid ?? 'anonymous',
        message:
            'Từ chối truy cập (RLS): Chỉ Chủ sở hữu (Owner) mới được phép chia sẻ hoặc thay đổi quyền truy cập tài liệu "${document.title}".',
      );
    }
  }
}
