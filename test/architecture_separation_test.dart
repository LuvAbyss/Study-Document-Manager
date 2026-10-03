import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/database/app_database.dart';
import 'package:study_document_manager/struct/models.dart';
import 'package:study_document_manager/struct/document_service.dart';

/// Lớp Mock Database triển khai giao diện IAppDatabase
/// Chứng minh khả năng thay thế linh hoạt (Dependency Inversion & Testability)
class MockTestDatabase implements IAppDatabase {
  final List<StudyDocument> mockDocs = [];
  final List<Subject> mockSubjects = [];

  @override
  Future<List<StudyDocument>> getAllDocuments() async => List.from(mockDocs);

  @override
  Future<StudyDocument?> getDocumentById(String id) async {
    try {
      return mockDocs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertDocument(StudyDocument doc) async {
    mockDocs.add(doc);
  }

  @override
  Future<void> updateDocument(StudyDocument doc) async {
    final index = mockDocs.indexWhere((d) => d.id == doc.id);
    if (index != -1) mockDocs[index] = doc;
  }

  @override
  Future<void> deleteDocument(String id) async {
    mockDocs.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final index = mockDocs.indexWhere((d) => d.id == id);
    if (index != -1) {
      mockDocs[index] = mockDocs[index].copyWith(isFavorite: !mockDocs[index].isFavorite);
    }
  }

  @override
  Future<void> updateDocumentStatus(String id, DocumentStatus newStatus) async {
    final index = mockDocs.indexWhere((d) => d.id == id);
    if (index != -1) {
      mockDocs[index] = mockDocs[index].copyWith(status: newStatus);
    }
  }

  @override
  Future<List<Subject>> getAllSubjects() async => List.from(mockSubjects);

  @override
  Future<Subject?> getSubjectById(String id) async {
    try {
      return mockSubjects.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> insertSubject(Subject subject) async => mockSubjects.add(subject);

  @override
  Future<void> updateSubject(Subject subject) async {
    final index = mockSubjects.indexWhere((s) => s.id == subject.id);
    if (index != -1) mockSubjects[index] = subject;
  }

  @override
  Future<void> deleteSubject(String id) async {
    mockSubjects.removeWhere((s) => s.id == id);
    mockDocs.removeWhere((d) => d.subjectId == id);
  }

  @override
  Stream<List<StudyDocument>> watchAllDocuments() => Stream.value(mockDocs);

  @override
  Stream<List<StudyDocument>> watchDocumentsWithFilter(DocumentFilter filter) {
    final filtered = DocumentService.filterAndSort(
      documents: mockDocs,
      filter: filter,
    );
    return Stream.value(filtered);
  }

  @override
  Stream<StudyDocument?> watchDocumentById(String id) {
    try {
      return Stream.value(mockDocs.firstWhere((d) => d.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Stream<List<Subject>> watchAllSubjects() => Stream.value(mockSubjects);

  @override
  Stream<Subject?> watchSubjectById(String id) {
    try {
      return Stream.value(mockSubjects.firstWhere((s) => s.id == id));
    } catch (_) {
      return Stream.value(null);
    }
  }

  @override
  Future<void> resetToSampleData() async {}

  @override
  Future<void> clearAll() async {
    mockDocs.clear();
    mockSubjects.clear();
  }

  @override
  void dispose() {}
}

void main() {
  group('Architecture Separation & Layer Isolation Verification', () {
    test('Tầng Nghiệp vụ (Struct/Service) không phụ thuộc vào Database hay UI', () {
      // DocumentService nhận dữ liệu thuần (POJO/Entities) và trả về kết quả
      final doc = StudyDocument(
        id: 'doc_arch_1',
        title: 'Tài liệu kiến trúc',
        subjectId: 'sub_1',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final val = DocumentService.validateDocument(doc);
      expect(val.isValid, true);

      // Thuật toán filter hoạt động độc lập không cần Flutter Widget context
      final filtered = DocumentService.filterAndSort(
        documents: [doc],
        filter: const DocumentFilter(type: DocumentType.lecture),
      );
      expect(filtered.length, 1);
    });

    test('Tầng Database trừu tượng hóa có thể thay thế bằng MockDatabase (IoC / DIP)', () async {
      final IAppDatabase mockDb = MockTestDatabase();

      final sub = Subject(
        id: 'sub_mock',
        code: 'MOCK101',
        name: 'Môn học kiểm thử',
        createdAt: DateTime.now(),
      );
      await mockDb.insertSubject(sub);

      final doc = StudyDocument(
        id: 'doc_mock',
        title: 'Tài liệu kiểm thử',
        subjectId: 'sub_mock',
        type: DocumentType.assignment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await mockDb.insertDocument(doc);

      final docs = await mockDb.getAllDocuments();
      expect(docs.length, 1);
      expect(docs.first.title, 'Tài liệu kiểm thử');

      // Kiểm thử cascade delete trên mockDb
      await mockDb.deleteSubject('sub_mock');
      expect((await mockDb.getAllDocuments()).isEmpty, true);
    });

    test('Tính toàn vẹn dữ liệu giữa các tầng (Data Integrity & Domain Consistency)', () async {
      final db = AppDatabase(populateSampleData: false);

      final subject = Subject(
        id: 'sub_valid',
        code: 'SE101',
        name: 'Môn học hợp lệ',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      // Model được validate trước khi đẩy xuống database
      final validDoc = StudyDocument(
        id: 'doc_valid',
        title: 'Slide bài giảng tuần 1',
        subjectId: subject.id,
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final validation = DocumentService.validateDocument(validDoc);
      expect(validation.isValid, true);

      // Lưu thành công
      await db.insertDocument(validDoc);
      final savedDoc = await db.getDocumentById(validDoc.id);
      expect(savedDoc, isNotNull);
      expect(savedDoc!.id, validDoc.id);

      db.dispose();
    });
  });
}
