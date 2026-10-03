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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      lecturer: (map['lecturer'] as String?) ?? '',
      colorValue: (map['colorValue'] as int?) ?? 0xFF1E88E5,
      iconName: (map['iconName'] as String?) ?? 'book',
      semester: (map['semester'] as String?) ?? 'HK1 2026-2027',
      creditCount: (map['creditCount'] as int?) ?? 3,
      createdAt: DateTime.parse(map['createdAt'] as String),
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
class StudyDocument {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final DocumentType type;
  final DocumentStatus status;
  final Priority priority;
  final String fileUrl; // Liên kết file / drive / local path
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
    required this.type,
    this.status = DocumentStatus.pending,
    this.priority = Priority.medium,
    this.fileUrl = '',
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

  StudyDocument copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    DocumentType? type,
    DocumentStatus? status,
    Priority? priority,
    String? fileUrl,
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
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      fileUrl: fileUrl ?? this.fileUrl,
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
      'type': type.name,
      'status': status.name,
      'priority': priority.name,
      'fileUrl': fileUrl,
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
    return StudyDocument(
      id: map['id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      subjectId: map['subjectId'] as String,
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
      fileUrl: (map['fileUrl'] as String?) ?? '',
      fileType: (map['fileType'] as String?) ?? 'PDF',
      fileSizeBytes: (map['fileSizeBytes'] as int?) ?? 0,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      tags: map['tags'] != null && (map['tags'] as String).isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
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
  final DocumentSortOption sortOption;

  const DocumentFilter({
    this.searchQuery,
    this.subjectId,
    this.type,
    this.status,
    this.priority,
    this.onlyFavorites,
    this.onlyHasDueDate,
    this.sortOption = DocumentSortOption.createdDesc,
  });

  bool get isActive {
    return (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
        subjectId != null ||
        type != null ||
        status != null ||
        priority != null ||
        (onlyFavorites == true) ||
        (onlyHasDueDate == true);
  }

  DocumentFilter copyWith({
    String? searchQuery,
    String? subjectId,
    DocumentType? type,
    DocumentStatus? status,
    Priority? priority,
    bool? onlyFavorites,
    bool? onlyHasDueDate,
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

  const StudyStatistics({
    required this.totalDocuments,
    required this.documentsByType,
    required this.documentsBySubject,
    required this.pendingAssignments,
    required this.overdueAssignments,
    required this.completedDocuments,
    required this.urgentCount,
  });

  double get completionRate {
    if (totalDocuments == 0) return 0.0;
    return (completedDocuments / totalDocuments).clamp(0.0, 1.0);
  }
}
