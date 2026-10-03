import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/struct/models.dart';
import 'package:study_document_manager/struct/document_service.dart';

void main() {
  group('Struct & Service Layer Tests (Pure Business Logic & Use Cases)', () {
    test('Xác thực tài liệu hợp lệ (Validation Success)', () {
      final doc = StudyDocument(
        id: 'valid_doc',
        title: 'Giáo trình Cấu trúc Dữ liệu',
        subjectId: 'sub_1',
        type: DocumentType.reference,
        fileUrl: 'https://example.com/books/dsa.pdf',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = DocumentService.validateDocument(doc);
      expect(result.isValid, true);
      expect(result.errors.isEmpty, true);
    });

    test('Xác thực thất bại khi tiêu đề rỗng hoặc quá ngắn', () {
      final docShort = StudyDocument(
        id: 'short_title',
        title: 'ab',
        subjectId: 'sub_1',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = DocumentService.validateDocument(docShort);
      expect(result.isValid, false);
      expect(result.errors.containsKey('title'), true);
    });

    test('Xác thực thất bại khi không chọn môn học', () {
      final docNoSubject = StudyDocument(
        id: 'no_sub',
        title: 'Slide bài giảng',
        subjectId: '',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = DocumentService.validateDocument(docNoSubject);
      expect(result.isValid, false);
      expect(result.errors.containsKey('subjectId'), true);
    });

    test('Xác thực môn học: mã môn rỗng hoặc tên rỗng sẽ không hợp lệ', () {
      final invalidSub = Subject(
        id: 'sub_inv',
        code: '',
        name: '',
        createdAt: DateTime.now(),
      );

      final result = DocumentService.validateSubject(invalidSub);
      expect(result.isValid, false);
      expect(result.errors.containsKey('code'), true);
      expect(result.errors.containsKey('name'), true);
    });

    test('Lọc tài liệu theo từ khóa tìm kiếm (Search Query)', () {
      final docs = [
        StudyDocument(
          id: '1',
          title: 'Kiến trúc Microservices',
          description: 'Học về Docker và Kubernetes',
          subjectId: 'sub_1',
          type: DocumentType.lecture,
          tags: ['cloud', 'microservices'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        StudyDocument(
          id: '2',
          title: 'Cơ sở dữ liệu NoSQL',
          description: 'Tìm hiểu MongoDB',
          subjectId: 'sub_2',
          type: DocumentType.assignment,
          tags: ['database'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Tìm kiếm theo từ trong description
      final filter1 = const DocumentFilter(searchQuery: 'Docker');
      final res1 = DocumentService.filterAndSort(documents: docs, filter: filter1);
      expect(res1.length, 1);
      expect(res1.first.id, '1');

      // Tìm kiếm theo tag
      final filter2 = const DocumentFilter(searchQuery: 'database');
      final res2 = DocumentService.filterAndSort(documents: docs, filter: filter2);
      expect(res2.length, 1);
      expect(res2.first.id, '2');
    });

    test('Lọc tài liệu theo loại tài liệu và mức độ ưu tiên kết hợp', () {
      final docs = [
        StudyDocument(
          id: '1',
          title: 'Bài tập 1',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          priority: Priority.urgent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        StudyDocument(
          id: '2',
          title: 'Bài tập 2',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          priority: Priority.low,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        StudyDocument(
          id: '3',
          title: 'Slide 1',
          subjectId: 'sub_1',
          type: DocumentType.lecture,
          priority: Priority.urgent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final filter = const DocumentFilter(
        type: DocumentType.assignment,
        priority: Priority.urgent,
      );

      final res = DocumentService.filterAndSort(documents: docs, filter: filter);
      expect(res.length, 1);
      expect(res.first.id, '1');
    });

    test('Sắp xếp tài liệu theo hạn nộp (dueDateAsc)', () {
      final now = DateTime.now();
      final docs = [
        StudyDocument(
          id: 'no_due',
          title: 'Không hạn',
          subjectId: 'sub_1',
          type: DocumentType.lecture,
          dueDate: null,
          createdAt: now,
          updatedAt: now,
        ),
        StudyDocument(
          id: 'due_later',
          title: 'Hạn sau',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          dueDate: now.add(const Duration(days: 7)),
          createdAt: now,
          updatedAt: now,
        ),
        StudyDocument(
          id: 'due_sooner',
          title: 'Hạn sớm',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          dueDate: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final res = DocumentService.filterAndSort(
        documents: docs,
        filter: const DocumentFilter(sortOption: DocumentSortOption.dueDateAsc),
      );

      expect(res[0].id, 'due_sooner');
      expect(res[1].id, 'due_later');
      expect(res[2].id, 'no_due'); // Đẩy tài liệu không có hạn về cuối
    });

    test('Tính toán số liệu thống kê (Study Statistics KPI)', () {
      final now = DateTime.now();
      final subjects = [
        Subject(id: 'sub_1', code: 'SE101', name: 'Môn 1', createdAt: now),
        Subject(id: 'sub_2', code: 'SE102', name: 'Môn 2', createdAt: now),
      ];

      final docs = [
        StudyDocument(
          id: '1',
          title: 'Bài tập 1 (đang làm)',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          status: DocumentStatus.inProgress,
          priority: Priority.urgent,
          createdAt: now,
          updatedAt: now,
        ),
        StudyDocument(
          id: '2',
          title: 'Bài tập 2 (hoàn thành)',
          subjectId: 'sub_1',
          type: DocumentType.assignment,
          status: DocumentStatus.completed,
          priority: Priority.medium,
          createdAt: now,
          updatedAt: now,
        ),
        StudyDocument(
          id: '3',
          title: 'Slide bài giảng',
          subjectId: 'sub_2',
          type: DocumentType.lecture,
          status: DocumentStatus.completed,
          priority: Priority.low,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final stats = DocumentService.computeStatistics(docs, subjects);

      expect(stats.totalDocuments, 3);
      expect(stats.pendingAssignments, 1);
      expect(stats.completedDocuments, 2);
      expect(stats.urgentCount, 1);
      expect(stats.completionRate, closeTo(2 / 3, 0.01));
      expect(stats.documentsBySubject['sub_1'], 2);
      expect(stats.documentsBySubject['sub_2'], 1);
    });

    test('Trích xuất tags thông minh từ nội dung văn bản', () {
      const title = 'Đề cương #midterm môn #architecture';
      const desc = 'Bao gồm kiến trúc phân lớp #cashew và design patterns';

      final tags = DocumentService.extractTags(title, desc);
      expect(tags.contains('midterm'), true);
      expect(tags.contains('architecture'), true);
      expect(tags.contains('cashew'), true);
      expect(tags.length, 3);
    });
  });
}
