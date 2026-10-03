import 'dart:async';
import '../struct/models.dart';
import '../struct/document_service.dart';
import 'default_preview_data.dart';

/// Giao diện chuẩn cho tầng Data Access / Database theo kiến trúc Cashew
abstract class IAppDatabase {
  Stream<List<StudyDocument>> watchAllDocuments();
  Stream<List<StudyDocument>> watchDocumentsWithFilter(DocumentFilter filter);
  Stream<StudyDocument?> watchDocumentById(String id);
  Stream<List<Subject>> watchAllSubjects();
  Stream<Subject?> watchSubjectById(String id);

  Future<List<StudyDocument>> getAllDocuments();
  Future<StudyDocument?> getDocumentById(String id);
  Future<void> insertDocument(StudyDocument doc);
  Future<void> updateDocument(StudyDocument doc);
  Future<void> deleteDocument(String id);
  Future<void> toggleFavorite(String id);
  Future<void> updateDocumentStatus(String id, DocumentStatus newStatus);

  Future<List<Subject>> getAllSubjects();
  Future<Subject?> getSubjectById(String id);
  Future<void> insertSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deleteSubject(String id);

  Future<void> resetToSampleData();
  Future<void> clearAll();
  void dispose();
}

/// Triển khai Database Reactive (Single Source of Truth)
/// Phản hồi thay đổi thông qua Streams, áp dụng chính xác mô hình Reactive của Cashew (Drift Watch pattern).
class AppDatabase implements IAppDatabase {
  final Map<String, StudyDocument> _documents = {};
  final Map<String, Subject> _subjects = {};

  final StreamController<List<StudyDocument>> _docsController =
      StreamController<List<StudyDocument>>.broadcast();
  final StreamController<List<Subject>> _subjectsController =
      StreamController<List<Subject>>.broadcast();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppDatabase({bool populateSampleData = true}) {
    if (populateSampleData) {
      _loadSampleData();
    }
    _isInitialized = true;
  }

  void _loadSampleData() {
    for (var sub in DefaultPreviewData.sampleSubjects) {
      _subjects[sub.id] = sub;
    }
    for (var doc in DefaultPreviewData.getSampleDocuments()) {
      _documents[doc.id] = doc;
    }
    _notifyAll();
  }

  void _notifyAll() {
    if (!_docsController.isClosed) {
      _docsController.add(List<StudyDocument>.unmodifiable(_documents.values.toList()));
    }
    if (!_subjectsController.isClosed) {
      _subjectsController.add(List<Subject>.unmodifiable(_subjects.values.toList()));
    }
  }

  // ================= DOCUMENT OPERATIONS (CRUD) =================

  @override
  Stream<List<StudyDocument>> watchAllDocuments() {
    // Trả về stream với giá trị hiện tại ngay lập tức, sau đó lắng nghe các thay đổi
    return _docsController.stream.transform(
      StreamTransformer<List<StudyDocument>, List<StudyDocument>>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
      ),
    ).asBroadcastStream(
      onListen: (sub) {
        _docsController.add(_documents.values.toList());
      },
    );
  }

  @override
  Stream<List<StudyDocument>> watchDocumentsWithFilter(DocumentFilter filter) {
    return _docsController.stream.map((docs) {
      return DocumentService.filterAndSort(
        documents: docs,
        filter: filter,
        subjectMap: _subjects,
      );
    }).asBroadcastStream(
      onListen: (sub) {
        _docsController.add(_documents.values.toList());
      },
    );
  }

  @override
  Stream<StudyDocument?> watchDocumentById(String id) {
    return _docsController.stream.map((_) => _documents[id]).asBroadcastStream(
      onListen: (sub) {
        _docsController.add(_documents.values.toList());
      },
    );
  }

  @override
  Future<List<StudyDocument>> getAllDocuments() async {
    return _documents.values.toList();
  }

  @override
  Future<StudyDocument?> getDocumentById(String id) async {
    return _documents[id];
  }

  @override
  Future<void> insertDocument(StudyDocument doc) async {
    // Ràng buộc toàn vẹn dữ liệu: môn học phải tồn tại
    if (!_subjects.containsKey(doc.subjectId)) {
      throw ArgumentError('Môn học với ID ${doc.subjectId} không tồn tại trong hệ thống');
    }
    _documents[doc.id] = doc;
    _notifyAll();
  }

  @override
  Future<void> updateDocument(StudyDocument doc) async {
    if (!_documents.containsKey(doc.id)) {
      throw ArgumentError('Không tìm thấy tài liệu với ID: ${doc.id}');
    }
    if (!_subjects.containsKey(doc.subjectId)) {
      throw ArgumentError('Môn học với ID ${doc.subjectId} không tồn tại trong hệ thống');
    }
    _documents[doc.id] = doc.copyWith(updatedAt: DateTime.now());
    _notifyAll();
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (_documents.remove(id) != null) {
      _notifyAll();
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = _documents[id];
    if (doc != null) {
      _documents[id] = doc.copyWith(
        isFavorite: !doc.isFavorite,
        updatedAt: DateTime.now(),
      );
      _notifyAll();
    }
  }

  @override
  Future<void> updateDocumentStatus(String id, DocumentStatus newStatus) async {
    final doc = _documents[id];
    if (doc != null) {
      _documents[id] = doc.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _notifyAll();
    }
  }

  // ================= SUBJECT OPERATIONS (CRUD) =================

  @override
  Stream<List<Subject>> watchAllSubjects() {
    return _subjectsController.stream.asBroadcastStream(
      onListen: (sub) {
        _subjectsController.add(_subjects.values.toList());
      },
    );
  }

  @override
  Stream<Subject?> watchSubjectById(String id) {
    return _subjectsController.stream.map((_) => _subjects[id]).asBroadcastStream(
      onListen: (sub) {
        _subjectsController.add(_subjects.values.toList());
      },
    );
  }

  @override
  Future<List<Subject>> getAllSubjects() async {
    return _subjects.values.toList();
  }

  @override
  Future<Subject?> getSubjectById(String id) async {
    return _subjects[id];
  }

  @override
  Future<void> insertSubject(Subject subject) async {
    _subjects[subject.id] = subject;
    _notifyAll();
  }

  @override
  Future<void> updateSubject(Subject subject) async {
    if (!_subjects.containsKey(subject.id)) {
      throw ArgumentError('Không tìm thấy môn học với ID: ${subject.id}');
    }
    _subjects[subject.id] = subject;
    _notifyAll();
  }

  @override
  Future<void> deleteSubject(String id) async {
    if (_subjects.remove(id) != null) {
      // Xóa tầng liên kết (Cascade Delete): xóa các tài liệu thuộc môn học này
      _documents.removeWhere((key, doc) => doc.subjectId == id);
      _notifyAll();
    }
  }

  @override
  Future<void> resetToSampleData() async {
    _documents.clear();
    _subjects.clear();
    _loadSampleData();
  }

  @override
  Future<void> clearAll() async {
    _documents.clear();
    _subjects.clear();
    _notifyAll();
  }

  @override
  void dispose() {
    _docsController.close();
    _subjectsController.close();
  }
}
