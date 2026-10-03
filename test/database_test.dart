import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/database/app_database.dart';
import 'package:study_document_manager/struct/models.dart';

void main() {
  group('Database Layer Tests (Data Persistence & Reactive Streams)', () {
    late AppDatabase db;

    setUp(() {
      // Khởi tạo database mới cho mỗi ca kiểm thử
      db = AppDatabase(populateSampleData: false);
    });

    tearDown(() {
      db.dispose();
    });

    test('Khởi tạo rỗng thành công', () async {
      final docs = await db.getAllDocuments();
      final subs = await db.getAllSubjects();
      expect(docs.isEmpty, true);
      expect(subs.isEmpty, true);
    });

    test('Thêm môn học và truy xuất chính xác', () async {
      final subject = Subject(
        id: 'sub_test',
        code: 'TEST101',
        name: 'Kiểm thử Phần mềm',
        createdAt: DateTime.now(),
      );

      await db.insertSubject(subject);

      final retrieved = await db.getSubjectById('sub_test');
      expect(retrieved, isNotNull);
      expect(retrieved!.code, 'TEST101');
      expect(retrieved.name, 'Kiểm thử Phần mềm');
    });

    test('Thêm tài liệu với môn học hợp lệ thành công', () async {
      final subject = Subject(
        id: 'sub_1',
        code: 'SE101',
        name: 'Nhập môn CNPM',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final doc = StudyDocument(
        id: 'doc_1',
        title: 'Slide Chương 1',
        subjectId: 'sub_1',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertDocument(doc);

      final retrieved = await db.getDocumentById('doc_1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Slide Chương 1');
      expect(retrieved.type, DocumentType.lecture);
    });

    test('Thêm tài liệu với môn học không tồn tại sẽ ném ArgumentError', () async {
      final doc = StudyDocument(
        id: 'doc_invalid',
        title: 'Tài liệu mồ côi',
        subjectId: 'sub_non_existent',
        type: DocumentType.reference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(() => db.insertDocument(doc), throwsArgumentError);
    });

    test('Cập nhật tài liệu (Update Document)', () async {
      final subject = Subject(
        id: 'sub_1',
        code: 'SE101',
        name: 'Nhập môn CNPM',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final doc = StudyDocument(
        id: 'doc_1',
        title: 'Tiêu đề ban đầu',
        subjectId: 'sub_1',
        type: DocumentType.assignment,
        status: DocumentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.insertDocument(doc);

      // Cập nhật trạng thái và tiêu đề
      final updated = doc.copyWith(
        title: 'Tiêu đề đã sửa',
        status: DocumentStatus.completed,
      );
      await db.updateDocument(updated);

      final result = await db.getDocumentById('doc_1');
      expect(result!.title, 'Tiêu đề đã sửa');
      expect(result.status, DocumentStatus.completed);
    });

    test('Xóa tài liệu (Delete Document)', () async {
      final subject = Subject(
        id: 'sub_1',
        code: 'SE101',
        name: 'Nhập môn CNPM',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final doc = StudyDocument(
        id: 'doc_delete',
        title: 'Tài liệu cần xóa',
        subjectId: 'sub_1',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.insertDocument(doc);

      await db.deleteDocument('doc_delete');
      final result = await db.getDocumentById('doc_delete');
      expect(result, isNull);
    });

    test('Xóa môn học sẽ tự động xóa các tài liệu liên kết (Cascade Delete)', () async {
      final subject = Subject(
        id: 'sub_cascade',
        code: 'SE999',
        name: 'Môn học sắp xóa',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final doc1 = StudyDocument(
        id: 'doc_c1',
        title: 'Tài liệu 1',
        subjectId: 'sub_cascade',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final doc2 = StudyDocument(
        id: 'doc_c2',
        title: 'Tài liệu 2',
        subjectId: 'sub_cascade',
        type: DocumentType.assignment,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await db.insertDocument(doc1);
      await db.insertDocument(doc2);

      expect((await db.getAllDocuments()).length, 2);

      // Xóa môn học
      await db.deleteSubject('sub_cascade');

      // Cả 2 tài liệu liên kết phải bị xóa theo
      expect((await db.getAllDocuments()).length, 0);
    });

    test('Kiểm tra cơ chế Reactive Stream (watchAllDocuments phản ứng khi dữ liệu thay đổi)', () async {
      final subject = Subject(
        id: 'sub_stream',
        code: 'STREAM101',
        name: 'Reactive Stream Test',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final stream = db.watchAllDocuments();

      expectLater(
        stream,
        emitsInOrder([
          isEmpty, // Lúc đầu rỗng
          hasLength(1), // Sau khi thêm doc 1
          hasLength(2), // Sau khi thêm doc 2
          hasLength(1), // Sau khi xóa 1 doc
        ]),
      );

      // Trigger emit 1
      await db.insertDocument(StudyDocument(
        id: 's_doc_1',
        title: 'Stream Doc 1',
        subjectId: 'sub_stream',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Trigger emit 2
      await db.insertDocument(StudyDocument(
        id: 's_doc_2',
        title: 'Stream Doc 2',
        subjectId: 'sub_stream',
        type: DocumentType.reference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Trigger emit 3
      await db.deleteDocument('s_doc_1');
    });

    test('Chuyển đổi trạng thái yêu thích (toggleFavorite)', () async {
      final subject = Subject(
        id: 'sub_fav',
        code: 'FAV101',
        name: 'Favorite Test',
        createdAt: DateTime.now(),
      );
      await db.insertSubject(subject);

      final doc = StudyDocument(
        id: 'doc_fav',
        title: 'Tài liệu yêu thích',
        subjectId: 'sub_fav',
        type: DocumentType.lecture,
        isFavorite: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await db.insertDocument(doc);

      await db.toggleFavorite('doc_fav');
      expect((await db.getDocumentById('doc_fav'))!.isFavorite, true);

      await db.toggleFavorite('doc_fav');
      expect((await db.getDocumentById('doc_fav'))!.isFavorite, false);
    });
  });
}
