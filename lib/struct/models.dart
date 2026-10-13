import 'package:flutter/material.dart';
import '../colors.dart';

/// Loại tài liệu học tập
enum DocumentType {
  lecture, // Bài giảng / Slide
  assignment, // Bài tập / Đồ án / Bài tập lớn
  reference, // Tài liệu tham khảo / Sách / Bài báo
  exam, // Đề thi / Đề cương ôn tập
}

extension DocumentTypeExtension on DocumentType {
  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.assignment:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
      case DocumentType.exam:
        return 'Đề thi / Ôn tập';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentType.lecture:
        return Icons.slideshow_rounded;
      case DocumentType.assignment:
        return Icons.assignment_rounded;
      case DocumentType.reference:
        return Icons.menu_book_rounded;
      case DocumentType.exam:
        return Icons.quiz_rounded;
    }
  }

  Color get color {
    switch (this) {
      case DocumentType.lecture:
        return AppColors.typeLecture;
      case DocumentType.assignment:
        return AppColors.typeAssignment;
      case DocumentType.reference:
        return AppColors.typeReference;
      case DocumentType.exam:
        return AppColors.typeExam;
    }
  }
}

/// Trạng thái học tập của tài liệu
enum DocumentStatus {
  pending, // Chưa học / Chưa làm
  inProgress, // Đang học / Đang làm
  completed, // Đã hoàn thành / Đã nộp
  archived, // Đã lưu trữ
}

extension DocumentStatusExtension on DocumentStatus {
  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Chưa làm';
      case DocumentStatus.inProgress:
        return 'Đang làm';
      case DocumentStatus.completed:
        return 'Đã hoàn thành';
      case DocumentStatus.archived:
        return 'Lưu trữ';
    }
  }

  Color get color {
    switch (this) {
      case DocumentStatus.pending:
        return AppColors.statusPending;
      case DocumentStatus.inProgress:
        return AppColors.statusInProgress;
      case DocumentStatus.completed:
        return AppColors.statusCompleted;
      case DocumentStatus.archived:
        return AppColors.statusArchived;
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentStatus.pending:
        return Icons.hourglass_empty_rounded;
      case DocumentStatus.inProgress:
        return Icons.pending_actions_rounded;
      case DocumentStatus.completed:
        return Icons.check_circle_rounded;
      case DocumentStatus.archived:
        return Icons.archive_rounded;
    }
  }
}

/// Mức độ ưu tiên
enum Priority {
  low,
  medium,
  high,
  urgent,
}

extension PriorityExtension on Priority {
  String get displayName {
    switch (this) {
      case Priority.low:
        return 'Thấp';
      case Priority.medium:
        return 'Trung bình';
      case Priority.high:
        return 'Cao';
      case Priority.urgent:
        return 'Khẩn cấp';
    }
  }

  Color get color {
    switch (this) {
      case Priority.low:
        return AppColors.priorityLow;
      case Priority.medium:
        return AppColors.priorityMedium;
      case Priority.high:
        return AppColors.priorityHigh;
      case Priority.urgent:
        return AppColors.priorityUrgent;
    }
  }

  int get level {
    switch (this) {
      case Priority.low:
        return 1;
      case Priority.medium:
        return 2;
      case Priority.high:
        return 3;
      case Priority.urgent:
        return 4;
    }
  }
}

/// Cấp độ phân quyền truy cập tài liệu trên Cloud (Supabase RLS)
enum PermissionLevel {
  owner, // Chủ sở hữu: Xem, Sửa, Xóa, Chia sẻ & Quản lý quyền
  editor, // Người chỉnh sửa: Xem, Tải về, Cập nhật thông tin & file
  viewer, // Người xem: Chỉ xem và tải tài liệu
  none, // Không có quyền truy cập
}

extension PermissionLevelExtension on PermissionLevel {
  String get displayName {
    switch (this) {
      case PermissionLevel.owner:
        return 'Chủ sở hữu (Owner)';
      case PermissionLevel.editor:
        return 'Chỉnh sửa (Editor)';
      case PermissionLevel.viewer:
        return 'Chỉ xem (Viewer)';
      case PermissionLevel.none:
        return 'Không có quyền';
    }
  }

  String get shortLabel {
    switch (this) {
      case PermissionLevel.owner:
        return 'Chủ sở hữu';
      case PermissionLevel.editor:
        return 'Được sửa';
      case PermissionLevel.viewer:
        return 'Chỉ xem';
      case PermissionLevel.none:
        return 'Bị chặn';
    }
  }

  String get description {
    switch (this) {
      case PermissionLevel.owner:
        return 'Toàn quyền xem, sửa, xóa tài liệu và cấp/thu hồi quyền chia sẻ.';
      case PermissionLevel.editor:
        return 'Được phép xem, tải tệp và cập nhật nội dung tài liệu (không được xóa hoặc đổi quyền chủ sở hữu).';
      case PermissionLevel.viewer:
        return 'Chỉ được xem thông tin và tải tệp đính kèm (không được chỉnh sửa hay xóa).';
      case PermissionLevel.none:
        return 'Bị chặn bởi chính sách bảo mật Row Level Security (RLS).';
    }
  }

  Color get color {
    switch (this) {
      case PermissionLevel.owner:
        return const Color(0xFF1E88E5);
      case PermissionLevel.editor:
        return const Color(0xFF00897B);
      case PermissionLevel.viewer:
        return const Color(0xFF8E24AA);
      case PermissionLevel.none:
        return const Color(0xFFE53935);
    }
  }

  IconData get icon {
    switch (this) {
      case PermissionLevel.owner:
        return Icons.verified_user_rounded;
      case PermissionLevel.editor:
        return Icons.edit_note_rounded;
      case PermissionLevel.viewer:
        return Icons.visibility_rounded;
      case PermissionLevel.none:
        return Icons.lock_outline_rounded;
    }
  }

  bool get canView =>
      this == PermissionLevel.owner ||
      this == PermissionLevel.editor ||
      this == PermissionLevel.viewer;

  bool get canEdit =>
      this == PermissionLevel.owner || this == PermissionLevel.editor;

  bool get canDelete => this == PermissionLevel.owner;

  bool get canManagePermissions => this == PermissionLevel.owner;
}

/// Bộ lọc phạm vi sở hữu / chia sẻ trên Cloud
enum DocumentOwnershipFilter {
  allAccessible, // Tất cả tài liệu có quyền truy cập (Owner + Shared)
  ownedByMe, // Tài liệu của tôi (Owner)
  sharedWithMe, // Được chia sẻ với tôi (Editor / Viewer)
}

extension DocumentOwnershipFilterExtension on DocumentOwnershipFilter {
  String get displayName {
    switch (this) {
      case DocumentOwnershipFilter.allAccessible:
        return 'Tất cả';
      case DocumentOwnershipFilter.ownedByMe:
        return 'Của tôi';
      case DocumentOwnershipFilter.sharedWithMe:
        return 'Được chia sẻ';
    }
  }

  IconData get icon {
    switch (this) {
      case DocumentOwnershipFilter.allAccessible:
        return Icons.cloud_done_rounded;
      case DocumentOwnershipFilter.ownedByMe:
        return Icons.person_rounded;
      case DocumentOwnershipFilter.sharedWithMe:
        return Icons.folder_shared_rounded;
    }
  }
}

/// Tùy chọn sắp xếp tài liệu
enum DocumentSortOption {
  createdDesc,
  createdAsc,
  dueDateAsc,
  titleAsc,
  priorityDesc,
}

extension DocumentSortOptionExtension on DocumentSortOption {
  String get displayName {
    switch (this) {
      case DocumentSortOption.createdDesc:
        return 'Mới nhất trước';
      case DocumentSortOption.createdAsc:
        return 'Cũ nhất trước';
      case DocumentSortOption.dueDateAsc:
        return 'Hạn nộp gần nhất';
      case DocumentSortOption.titleAsc:
        return 'Theo tên A-Z';
      case DocumentSortOption.priorityDesc:
        return 'Ưu tiên cao nhất';
    }
  }
}

/// Thực thể Người dùng (User Entity) - Đồng bộ giữa Firebase Auth (Google) và Supabase `users`
class AppUser {
  final String uid; // Firebase Auth UID
  final String email; // Gmail
  final String displayName; // Tên hiển thị
  final String photoUrl; // Ảnh đại diện Google
  final String roleTitle; // Giảng viên / Trợ giảng / Sinh viên
  final String department; // Khoa / Bộ môn
  final int avatarColorValue;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl = '',
    this.roleTitle = 'Sinh viên',
    this.department = 'Khoa CNTT',
    this.avatarColorValue = 0xFF1E88E5,
    required this.createdAt,
    required this.lastLoginAt,
  });

  Color get avatarColor => Color(avatarColorValue);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    String? roleTitle,
    String? department,
    int? avatarColorValue,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      roleTitle: roleTitle ?? this.roleTitle,
      department: department ?? this.department,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role_title': roleTitle,
      'department': department,
      'avatar_color_value': avatarColorValue,
      'created_at': createdAt.toIso8601String(),
      'last_login_at': lastLoginAt.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final nowIso = DateTime.now().toIso8601String();
    return AppUser(
      uid: (map['uid'] ?? map['id']) as String,
      email: map['email'] as String,
      displayName: (map['display_name'] ?? map['displayName'] ?? '') as String,
      photoUrl: (map['photo_url'] ?? map['photoUrl'] ?? '') as String,
      roleTitle: (map['role_title'] ?? map['roleTitle'] ?? 'Sinh viên') as String,
      department: (map['department'] ?? 'Khoa CNTT') as String,
      avatarColorValue: (map['avatar_color_value'] as int?) ?? 0xFF1E88E5,
      createdAt: DateTime.parse((map['created_at'] ?? map['createdAt'] ?? nowIso) as String),
      lastLoginAt: DateTime.parse((map['last_login_at'] ?? map['lastLoginAt'] ?? nowIso) as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

/// Thực thể Quyền chia sẻ tài liệu (Permission Entity) trên Supabase `permissions`
class DocumentPermission {
  final String id;
  final String documentId;
  final String sharedWithUid;
  final String sharedWithEmail;
  final String sharedWithName;
  final PermissionLevel permissionLevel; // viewer hoặc editor
  final String grantedByUid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DocumentPermission({
    required this.id,
    required this.documentId,
    required this.sharedWithUid,
    required this.sharedWithEmail,
    this.sharedWithName = '',
    required this.permissionLevel,
    required this.grantedByUid,
    required this.createdAt,
    required this.updatedAt,
  });

  DocumentPermission copyWith({
    String? id,
    String? documentId,
    String? sharedWithUid,
    String? sharedWithEmail,
    String? sharedWithName,
    PermissionLevel? permissionLevel,
    String? grantedByUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DocumentPermission(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      sharedWithUid: sharedWithUid ?? this.sharedWithUid,
      sharedWithEmail: sharedWithEmail ?? this.sharedWithEmail,
      sharedWithName: sharedWithName ?? this.sharedWithName,
      permissionLevel: permissionLevel ?? this.permissionLevel,
      grantedByUid: grantedByUid ?? this.grantedByUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'shared_with_uid': sharedWithUid,
      'shared_with_email': sharedWithEmail,
      'shared_with_name': sharedWithName,
      'permission_level': permissionLevel.name,
      'granted_by_uid': grantedByUid,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DocumentPermission.fromMap(Map<String, dynamic> map) {
    final nowIso = DateTime.now().toIso8601String();
    final levelStr = (map['permission_level'] ?? map['permissionLevel'] ?? 'viewer') as String;
    return DocumentPermission(
      id: map['id'] as String,
      documentId: (map['document_id'] ?? map['documentId']) as String,
      sharedWithUid: (map['shared_with_uid'] ?? map['sharedWithUid']) as String,
      sharedWithEmail: (map['shared_with_email'] ?? map['sharedWithEmail']) as String,
      sharedWithName: (map['shared_with_name'] ?? map['sharedWithName'] ?? '') as String,
      permissionLevel: PermissionLevel.values.firstWhere(
        (e) => e.name == levelStr,
        orElse: () => PermissionLevel.viewer,
      ),
      grantedByUid: (map['granted_by_uid'] ?? map['grantedByUid']) as String,
      createdAt: DateTime.parse((map['created_at'] ?? map['createdAt'] ?? nowIso) as String),
      updatedAt: DateTime.parse((map['updated_at'] ?? map['updatedAt'] ?? nowIso) as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPermission && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Thực thể Môn học / Học phần (Subject Entity)
class Subject {
  final String id;
  final String code; // Mã môn học (vd: CS101, SE301)
  final String name; // Tên môn học
  final String lecturer; // Giảng viên
  final int colorValue; // Mã màu nhận diện
  final String iconName; // Icon hiển thị
  final String semester; // Học kỳ (vd: HK1 2026-2027)
  final int creditCount; // Số tín chỉ
  final String ownerUid; // Người tạo môn học
  final DateTime createdAt;

  const Subject({
    required this.id,
    required this.code,
    required this.name,
    this.lecturer = '',
    this.colorValue = 0xFF1E88E5,
    this.iconName = 'book',
    this.semester = 'HK1 2026-2027',
    this.creditCount = 3,
    this.ownerUid = 'uid_user_1',
    required this.createdAt,
  });

  Color get color => Color(colorValue);

  Subject copyWith({
    String? id,
    String? code,
    String? name,
    String? lecturer,
    int? colorValue,
    String? iconName,
    String? semester,
    int? creditCount,
    String? ownerUid,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      colorValue: colorValue ?? this.colorValue,
      iconName: iconName ?? this.iconName,
      semester: semester ?? this.semester,
      creditCount: creditCount ?? this.creditCount,
      ownerUid: ownerUid ?? this.ownerUid,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'lecturer': lecturer,
      'colorValue': colorValue,
      'iconName': iconName,
      'semester': semester,
      'creditCount': creditCount,
      'ownerUid': ownerUid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      lecturer: (map['lecturer'] as String?) ?? '',
      colorValue: (map['colorValue'] ?? map['color_value'] as int?) ?? 0xFF1E88E5,
      iconName: (map['iconName'] ?? map['icon_name'] as String?) ?? 'book',
      semester: (map['semester'] as String?) ?? 'HK1 2026-2027',
      creditCount: (map['creditCount'] ?? map['credit_count'] as int?) ?? 3,
      ownerUid: (map['ownerUid'] ?? map['owner_uid'] as String?) ?? 'uid_user_1',
      createdAt: DateTime.parse((map['createdAt'] ?? map['created_at']) as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Thực thể Tài liệu học tập (Study Document Entity)
/// Tích hợp thông tin lưu trữ vật lý trên Firebase Storage và quyền sở hữu trên Supabase
class StudyDocument {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final String ownerUid; // UID của người tạo tài liệu (Firebase Auth / Supabase)
  final String ownerName; // Tên người sở hữu
  final String ownerEmail; // Email người sở hữu
  final DocumentType type;
  final DocumentStatus status;
  final Priority priority;
  final String fileUrl; // Liên kết tải file từ Firebase Storage hoặc URL
  final String storagePath; // Đường dẫn trên Firebase Storage: users/{ownerUid}/subjects/{subjectId}/documents/{docId}/{fileName}
  final String fileName; // Tên file vật lý
  final String fileType; // PDF, PPTX, DOCX, ZIP, URL...
  final int fileSizeBytes;
  final DateTime? dueDate; // Hạn nộp bài tập / ngày thi
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyDocument({
    required this.id,
    required this.title,
    this.description = '',
    required this.subjectId,
    this.ownerUid = 'uid_user_1',
    this.ownerName = 'TS. Nguyễn Văn An',
    this.ownerEmail = 'an.nguyen@edu.vn',
    required this.type,
    this.status = DocumentStatus.pending,
    this.priority = Priority.medium,
    this.fileUrl = '',
    this.storagePath = '',
    this.fileName = '',
    this.fileType = 'PDF',
    this.fileSizeBytes = 0,
    this.dueDate,
    this.isFavorite = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (dueDate == null || status == DocumentStatus.completed) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  int? get daysUntilDue {
    if (dueDate == null) return null;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff;
  }

  /// Kiểm tra tài liệu có lưu trữ tệp vật lý trên Firebase Storage hay không
  bool get isStoredOnFirebase => storagePath.trim().isNotEmpty;

  StudyDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? ownerUid,
    String? ownerName,
    String? ownerEmail,
    DocumentType? type,
    DocumentStatus? status,
    Priority? priority,
    String? fileUrl,
    String? storagePath,
    String? fileName,
    String? fileType,
    int? fileSizeBytes,
    DateTime? dueDate,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      dueDate: dueDate ?? this.dueDate,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'fileName': fileName,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'dueDate': dueDate?.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'tags': tags.join(','),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyDocument.fromMap(Map<String, dynamic> map) {
    final rawTags = map['tags'];
    List<String> parsedTags = [];
    if (rawTags is List) {
      parsedTags = rawTags.map((e) => e.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      parsedTags = rawTags.split(',');
    }

    return StudyDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      subjectId: (map['subjectId'] ?? map['subject_id']) as String,
      ownerUid: (map['ownerUid'] ?? map['owner_uid'] as String?) ?? 'uid_user_1',
      ownerName: (map['ownerName'] ?? map['owner_name'] as String?) ?? 'TS. Nguyễn Văn An',
      ownerEmail: (map['ownerEmail'] ?? map['owner_email'] as String?) ?? 'an.nguyen@edu.vn',
      type: DocumentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DocumentType.lecture,
      ),
      status: DocumentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DocumentStatus.pending,
      ),
      priority: Priority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      fileUrl: (map['fileUrl'] ?? map['file_url'] as String?) ?? '',
      storagePath: (map['storagePath'] ?? map['storage_path'] as String?) ?? '',
      fileName: (map['fileName'] ?? map['file_name'] as String?) ?? '',
      fileType: (map['fileType'] ?? map['file_type'] as String?) ?? 'PDF',
      fileSizeBytes: (map['fileSizeBytes'] ?? map['file_size_bytes'] as int?) ?? 0,
      dueDate: (map['dueDate'] ?? map['due_date']) != null
          ? DateTime.parse((map['dueDate'] ?? map['due_date']) as String)
          : null,
      isFavorite: (map['isFavorite'] == 1 ||
          map['isFavorite'] == true ||
          map['is_favorite'] == true),
      tags: parsedTags,
      createdAt: DateTime.parse((map['createdAt'] ?? map['created_at']) as String),
      updatedAt: DateTime.parse((map['updatedAt'] ?? map['updated_at']) as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyDocument && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Bộ lọc tìm kiếm và phân loại tài liệu
class DocumentFilter {
  final String? searchQuery;
  final String? subjectId;
  final DocumentType? type;
  final DocumentStatus? status;
  final Priority? priority;
  final bool? onlyFavorites;
  final bool? onlyHasDueDate;
  final DocumentOwnershipFilter ownershipFilter;
  final DocumentSortOption sortOption;

  const DocumentFilter({
    this.searchQuery,
    this.subjectId,
    this.type,
    this.status,
    this.priority,
    this.onlyFavorites,
    this.onlyHasDueDate,
    this.ownershipFilter = DocumentOwnershipFilter.allAccessible,
    this.sortOption = DocumentSortOption.createdDesc,
  });

  bool get isActive {
    return (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
        subjectId != null ||
        type != null ||
        status != null ||
        priority != null ||
        (onlyFavorites == true) ||
        (onlyHasDueDate == true) ||
        ownershipFilter != DocumentOwnershipFilter.allAccessible;
  }

  DocumentFilter copyWith({
    String? searchQuery,
    String? subjectId,
    DocumentType? type,
    DocumentStatus? status,
    Priority? priority,
    bool? onlyFavorites,
    bool? onlyHasDueDate,
    DocumentOwnershipFilter? ownershipFilter,
    DocumentSortOption? sortOption,
    bool clearSearchQuery = false,
    bool clearSubjectId = false,
    bool clearType = false,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return DocumentFilter(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
      type: clearType ? null : (type ?? this.type),
      status: clearStatus ? null : (status ?? this.status),
      priority: clearPriority ? null : (priority ?? this.priority),
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyHasDueDate: onlyHasDueDate ?? this.onlyHasDueDate,
      ownershipFilter: ownershipFilter ?? this.ownershipFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

/// Chỉ số thống kê học tập (Dashboard Statistics)
class StudyStatistics {
  final int totalDocuments;
  final Map<DocumentType, int> documentsByType;
  final Map<String, int> documentsBySubject;
  final int pendingAssignments;
  final int overdueAssignments;
  final int completedDocuments;
  final int urgentCount;
  final int ownedCount;
  final int sharedWithMeCount;

  const StudyStatistics({
    required this.totalDocuments,
    required this.documentsByType,
    required this.documentsBySubject,
    required this.pendingAssignments,
    required this.overdueAssignments,
    required this.completedDocuments,
    required this.urgentCount,
    this.ownedCount = 0,
    this.sharedWithMeCount = 0,
  });

  double get completionRate {
    if (totalDocuments == 0) return 0.0;
    return (completedDocuments / totalDocuments).clamp(0.0, 1.0);
  }
}
