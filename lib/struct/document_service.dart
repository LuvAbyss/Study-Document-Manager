import 'models.dart';

/// Kết quả kiểm tra dữ liệu hợp lệ (Validation Result)
class ValidationResult {
  final bool isValid;
  final Map<String, String> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const {},
  });

  factory ValidationResult.success() => const ValidationResult(isValid: true);
  factory ValidationResult.failure(Map<String, String> errors) =>
      ValidationResult(isValid: false, errors: errors);
}

/// Tầng Xử lý Nghiệp vụ & Use Cases (Business Logic / Service Layer)
/// Độc lập hoàn toàn với UI Flutter và cách thức lưu trữ dữ liệu.
class DocumentService {
  /// Xác thực tính hợp lệ của tài liệu học tập trước khi lưu trữ
  static ValidationResult validateDocument(StudyDocument doc) {
    final errors = <String, String>{};

    // Kiểm tra tiêu đề
    if (doc.title.trim().isEmpty) {
      errors['title'] = 'Tiêu đề tài liệu không được để trống';
    } else if (doc.title.trim().length < 3) {
      errors['title'] = 'Tiêu đề phải có ít nhất 3 ký tự';
    } else if (doc.title.length > 250) {
      errors['title'] = 'Tiêu đề không được vượt quá 250 ký tự';
    }

    // Kiểm tra môn học liên kết
    if (doc.subjectId.trim().isEmpty) {
      errors['subjectId'] = 'Vui lòng chọn môn học liên kết';
    }

    // Kiểm tra định dạng liên kết tệp tin (nếu có)
    if (doc.fileUrl.isNotEmpty) {
      final uri = Uri.tryParse(doc.fileUrl);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https') && !uri.hasScheme)) {
        // Cho phép đường dẫn file cục bộ hoặc URL chuẩn
        if (!doc.fileUrl.startsWith('/') && !doc.fileUrl.contains(':\\') && !doc.fileUrl.contains('://')) {
          errors['fileUrl'] = 'Đường dẫn liên kết hoặc file không hợp lệ';
        }
      }
    }

    // Kiểm tra tính hợp lệ của hạn nộp đối với bài tập
    if (doc.type == DocumentType.assignment && doc.dueDate != null) {
      // Đối với bài tập mới, cảnh báo nếu hạn nộp nằm ở quá khứ xa (> 30 ngày)
      final now = DateTime.now();
      if (doc.dueDate!.isBefore(now.subtract(const Duration(days: 30)))) {
        errors['dueDate'] = 'Hạn nộp quá xa trong quá khứ';
      }
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Xác thực tính hợp lệ của môn học
  static ValidationResult validateSubject(Subject subject) {
    final errors = <String, String>{};

    if (subject.code.trim().isEmpty) {
      errors['code'] = 'Mã môn học không được để trống';
    } else if (subject.code.trim().length > 15) {
      errors['code'] = 'Mã môn học không được dài hơn 15 ký tự';
    }

    if (subject.name.trim().isEmpty) {
      errors['name'] = 'Tên môn học không được để trống';
    }

    if (subject.creditCount < 0 || subject.creditCount > 20) {
      errors['creditCount'] = 'Số tín chỉ không hợp lệ';
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Thuật toán Lọc và Sắp xếp tài liệu thuần (Pure Function for Filtering & Sorting)
  static List<StudyDocument> filterAndSort({
    required List<StudyDocument> documents,
    required DocumentFilter filter,
    Map<String, Subject>? subjectMap,
  }) {
    var result = List<StudyDocument>.from(documents);

    // 1. Lọc theo từ khóa tìm kiếm (Search Query)
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final query = filter.searchQuery!.trim().toLowerCase();
      result = result.where((doc) {
        final titleMatch = doc.title.toLowerCase().contains(query);
        final descMatch = doc.description.toLowerCase().contains(query);
        final tagMatch = doc.tags.any((tag) => tag.toLowerCase().contains(query));

        // Tìm theo tên môn học nếu có map
        var subjectMatch = false;
        if (subjectMap != null && subjectMap.containsKey(doc.subjectId)) {
          final sub = subjectMap[doc.subjectId]!;
          subjectMatch = sub.name.toLowerCase().contains(query) ||
              sub.code.toLowerCase().contains(query);
        }

        return titleMatch || descMatch || tagMatch || subjectMatch;
      }).toList();
    }

    // 2. Lọc theo Môn học
    if (filter.subjectId != null) {
      result = result.where((d) => d.subjectId == filter.subjectId).toList();
    }

    // 3. Lọc theo Loại tài liệu
    if (filter.type != null) {
      result = result.where((d) => d.type == filter.type).toList();
    }

    // 4. Lọc theo Trạng thái
    if (filter.status != null) {
      result = result.where((d) => d.status == filter.status).toList();
    }

    // 5. Lọc theo Mức độ ưu tiên
    if (filter.priority != null) {
      result = result.where((d) => d.priority == filter.priority).toList();
    }

    // 6. Lọc chỉ yêu thích
    if (filter.onlyFavorites == true) {
      result = result.where((d) => d.isFavorite).toList();
    }

    // 7. Lọc chỉ có hạn nộp
    if (filter.onlyHasDueDate == true) {
      result = result.where((d) => d.dueDate != null).toList();
    }

    // 8. Sắp xếp kết quả (Multi-criteria Sorting)
    switch (filter.sortOption) {
      case DocumentSortOption.createdDesc:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DocumentSortOption.createdAsc:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DocumentSortOption.titleAsc:
        result.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case DocumentSortOption.priorityDesc:
        result.sort((a, b) => b.priority.level.compareTo(a.priority.level));
        break;
      case DocumentSortOption.dueDateAsc:
        result.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1; // Đẩy không có hạn về cuối
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
    }

    return result;
  }

  /// Tính toán tổng hợp số liệu thống kê học tập (KPI & Statistics)
  static StudyStatistics computeStatistics(
    List<StudyDocument> documents,
    List<Subject> subjects,
  ) {
    final byType = <DocumentType, int>{
      for (var type in DocumentType.values) type: 0,
    };
    final bySubject = <String, int>{
      for (var sub in subjects) sub.id: 0,
    };

    var pendingAssignments = 0;
    var overdueAssignments = 0;
    var completed = 0;
    var urgent = 0;

    for (var doc in documents) {
      byType[doc.type] = (byType[doc.type] ?? 0) + 1;

      if (bySubject.containsKey(doc.subjectId)) {
        bySubject[doc.subjectId] = (bySubject[doc.subjectId] ?? 0) + 1;
      }

      if (doc.type == DocumentType.assignment) {
        if (doc.status != DocumentStatus.completed) {
          pendingAssignments++;
          if (doc.isOverdue) {
            overdueAssignments++;
          }
        }
      }

      if (doc.status == DocumentStatus.completed) {
        completed++;
      }

      if (doc.priority == Priority.urgent && doc.status != DocumentStatus.completed) {
        urgent++;
      }
    }

    return StudyStatistics(
      totalDocuments: documents.length,
      documentsByType: byType,
      documentsBySubject: bySubject,
      pendingAssignments: pendingAssignments,
      overdueAssignments: overdueAssignments,
      completedDocuments: completed,
      urgentCount: urgent,
    );
  }

  /// Trích xuất danh sách tags gợi ý từ tiêu đề và nội dung
  static List<String> extractTags(String title, String description) {
    final text = '$title $description';
    final regExp = RegExp(r'#(\w+)');
    final matches = regExp.allMatches(text);
    final tags = <String>{};
    for (var match in matches) {
      if (match.group(1) != null) {
        tags.add(match.group(1)!.toLowerCase());
      }
    }
    return tags.toList();
  }
}
