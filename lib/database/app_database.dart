import 'dart:async';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../cloud/rls_policy_engine.dart';
import '../cloud/storage_service.dart';
import '../cloud/supabase_sync_service.dart';
import '../struct/document_service.dart';
import '../struct/models.dart';
import 'default_preview_data.dart';

/// Giao diện chuẩn cho tầng Data Access / Database theo kiến trúc Cashew & Hệ sinh thái Cloud (Supabase + Firebase)
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

  // ================= CLOUD AUTH, USERS, STORAGE & RLS PERMISSIONS =================

  String? get currentUserUid => 'uid_user_1';
  AppUser? get currentUser => null;

  Stream<AppUser?> watchCurrentUser() => Stream.value(currentUser);
  Stream<List<AppUser>> watchAllUsers() => const Stream.empty();

  Future<void> setCurrentUser(String? uid) async {}
  Future<List<AppUser>> getAllUsers() async => const [];
  Future<AppUser?> getUserByUid(String uid) async => null;
  Future<AppUser?> getUserByEmail(String email) async => null;
  Future<void> upsertUser(AppUser user) async {}

  /// Lấy cấp độ quyền hiệu lực (RLS) của người dùng đối với tài liệu
  PermissionLevel getEffectivePermission(String documentId, {String? userUid}) =>
      PermissionLevel.owner;

  Stream<List<DocumentPermission>> watchPermissionsForDocument(String documentId) =>
      const Stream.empty();

  Future<List<DocumentPermission>> getPermissionsForDocument(String documentId) async =>
      const [];

  Future<List<DocumentPermission>> getAllPermissions() async => const [];

  /// Chia sẻ tài liệu cho người dùng khác qua Email với phân quyền `viewer` hoặc `editor`
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permissionLevel,
  }) {
    throw UnimplementedError();
  }

  /// Cập nhật cấp độ quyền chia sẻ (chỉ Owner được phép)
  Future<DocumentPermission> updatePermissionLevel({
    required String permissionId,
    required PermissionLevel newLevel,
  }) {
    throw UnimplementedError();
  }

  /// Thu hồi quyền chia sẻ tài liệu
  Future<void> revokePermission(String permissionId) async {}

  /// Tải tệp vật lý lên Firebase Storage và gắn kết với bản ghi tài liệu trên Supabase
  Future<StorageUploadResult> uploadFileToStorage({
    required String documentId,
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
    required String fileType,
  }) {
    throw UnimplementedError();
  }
}

/// Triển khai Database Reactive tích hợp Supabase Relational Schema, Firebase Storage & Row Level Security (RLS)
class AppDatabase extends IAppDatabase {
  final Map<String, AppUser> _users = {};
  final Map<String, Subject> _subjects = {};
  final Map<String, StudyDocument> _documents = {};
  final Map<String, DocumentPermission> _permissions = {};

  String? _currentUserUid = 'uid_user_1';
  final bool enforceRls;

  final StreamController<List<StudyDocument>> _docsController =
      StreamController<List<StudyDocument>>.broadcast();
  final StreamController<List<Subject>> _subjectsController =
      StreamController<List<Subject>>.broadcast();
  final StreamController<AppUser?> _currentUserController =
      StreamController<AppUser?>.broadcast();
  final StreamController<List<AppUser>> _usersController =
      StreamController<List<AppUser>>.broadcast();
  final StreamController<List<DocumentPermission>> _permissionsController =
      StreamController<List<DocumentPermission>>.broadcast();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppDatabase({
    bool populateSampleData = true,
    this.enforceRls = true,
    String? initialUserUid = 'uid_user_1',
  }) {
    _currentUserUid = initialUserUid;
    _seedDefaultUsers();
    if (populateSampleData) {
      _loadSampleData();
    }
    _isInitialized = true;
  }

  void _seedDefaultUsers() {
    for (final user in DefaultPreviewData.getSampleUsers()) {
      _users[user.uid] = user;
    }
  }

  void _loadSampleData() {
    _seedDefaultUsers();
    for (final sub in DefaultPreviewData.sampleSubjects) {
      _subjects[sub.id] = sub;
    }
    for (final doc in DefaultPreviewData.getSampleDocuments()) {
      _documents[doc.id] = doc;
      if (doc.isStoredOnFirebase) {
        FirebaseStorageService.instance.seedSampleFile(
          storagePath: doc.storagePath,
          downloadUrl: doc.fileUrl,
          fileName: doc.fileName,
          fileType: doc.fileType,
          fileSizeBytes: doc.fileSizeBytes,
          ownerUid: doc.ownerUid,
        );
      }
    }
    for (final perm in DefaultPreviewData.getSamplePermissions()) {
      _permissions[perm.id] = perm;
    }
    _notifyAll();
  }

  List<StudyDocument> _getAccessibleDocumentsForCurrentUser() {
    if (!enforceRls) {
      return _documents.values.toList();
    }
    return RlsPolicyEngine.filterAccessibleDocuments(
      allDocuments: _documents.values,
      allPermissions: _permissions.values,
      currentUserUid: _currentUserUid,
    );
  }

  void _notifyAll() {
    if (!_docsController.isClosed) {
      _docsController.add(
        List<StudyDocument>.unmodifiable(_getAccessibleDocumentsForCurrentUser()),
      );
    }
    if (!_subjectsController.isClosed) {
      _subjectsController.add(
        List<Subject>.unmodifiable(_subjects.values.toList()),
      );
    }
    if (!_currentUserController.isClosed) {
      _currentUserController.add(currentUser);
    }
    if (!_usersController.isClosed) {
      _usersController.add(
        List<AppUser>.unmodifiable(_users.values.toList()),
      );
    }
    if (!_permissionsController.isClosed) {
      _permissionsController.add(
        List<DocumentPermission>.unmodifiable(_permissions.values.toList()),
      );
    }
  }

  // ================= USER & GOOGLE AUTH OPERATIONS =================

  @override
  String? get currentUserUid => _currentUserUid;

  @override
  AppUser? get currentUser =>
      _currentUserUid != null ? _users[_currentUserUid] : null;

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _currentUserController.stream.asBroadcastStream(
      onListen: (_) {
        _currentUserController.add(currentUser);
      },
    );
  }

  @override
  Stream<List<AppUser>> watchAllUsers() {
    return _usersController.stream.asBroadcastStream(
      onListen: (_) {
        _usersController.add(_users.values.toList());
      },
    );
  }

  @override
  Future<void> setCurrentUser(String? uid) async {
    if (uid != null && !_users.containsKey(uid)) {
      throw ArgumentError('Không tìm thấy người dùng với UID: $uid');
    }
    _currentUserUid = uid;
    _notifyAll();
  }

  @override
  Future<List<AppUser>> getAllUsers() async {
    return _users.values.toList();
  }

  @override
  Future<AppUser?> getUserByUid(String uid) async {
    return _users[uid];
  }

  @override
  Future<AppUser?> getUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    for (final user in _users.values) {
      if (user.email.trim().toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  @override
  Future<void> upsertUser(AppUser user) async {
    if (enforceRls && _currentUserUid != null && _currentUserUid != user.uid) {
      // Cho phép khởi tạo hoặc chính chủ cập nhật
      if (_users.containsKey(user.uid)) {
        throw RlsAccessDeniedException(
          policyName: 'users_update_self',
          operation: 'UPDATE',
          userUid: _currentUserUid!,
          message: 'Từ chối truy cập (RLS): Không thể sửa hồ sơ của người dùng khác.',
        );
      }
    }
    _users[user.uid] = user;
    await SupabaseSyncService.instance.upsertUserToSupabase(user);
    _notifyAll();
  }

  // ================= DOCUMENT OPERATIONS (CRUD + RLS) =================

  @override
  PermissionLevel getEffectivePermission(String documentId, {String? userUid}) {
    final doc = _documents[documentId];
    if (doc == null) return PermissionLevel.none;
    return RlsPolicyEngine.resolvePermissionLevel(
      document: doc,
      permissions: _permissions.values,
      userUid: userUid ?? _currentUserUid,
    );
  }

  @override
  Stream<List<StudyDocument>> watchAllDocuments() {
    return _docsController.stream
        .transform(
          StreamTransformer<List<StudyDocument>, List<StudyDocument>>.fromHandlers(
            handleData: (data, sink) => sink.add(data),
          ),
        )
        .asBroadcastStream(
          onListen: (sub) {
            _docsController.add(_getAccessibleDocumentsForCurrentUser());
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
        currentUserUid: _currentUserUid,
      );
    }).asBroadcastStream(
      onListen: (sub) {
        _docsController.add(_getAccessibleDocumentsForCurrentUser());
      },
    );
  }

  @override
  Stream<StudyDocument?> watchDocumentById(String id) {
    return _docsController.stream.map((_) {
      final doc = _documents[id];
      if (doc == null) return null;
      if (enforceRls) {
        final level = RlsPolicyEngine.resolvePermissionLevel(
          document: doc,
          permissions: _permissions.values,
          userUid: _currentUserUid,
        );
        if (!level.canView) return null;
      }
      return doc;
    }).asBroadcastStream(
      onListen: (sub) {
        _docsController.add(_getAccessibleDocumentsForCurrentUser());
      },
    );
  }

  @override
  Future<List<StudyDocument>> getAllDocuments() async {
    return _getAccessibleDocumentsForCurrentUser();
  }

  @override
  Future<StudyDocument?> getDocumentById(String id) async {
    final doc = _documents[id];
    if (doc == null) return null;
    if (enforceRls) {
      final level = RlsPolicyEngine.resolvePermissionLevel(
        document: doc,
        permissions: _permissions.values,
        userUid: _currentUserUid,
      );
      if (!level.canView) return null;
    }
    return doc;
  }

  @override
  Future<void> insertDocument(StudyDocument doc) async {
    // Ràng buộc toàn vẹn dữ liệu: môn học phải tồn tại
    if (!_subjects.containsKey(doc.subjectId)) {
      throw ArgumentError(
        'Môn học với ID ${doc.subjectId} không tồn tại trong hệ thống',
      );
    }

    // Tự động gắn thông tin người dùng đang đăng nhập nếu chưa chỉ định khác
    var docToInsert = doc;
    final activeUser = currentUser;
    if (activeUser != null && doc.ownerUid == 'uid_user_1' && _currentUserUid != 'uid_user_1') {
      docToInsert = doc.copyWith(
        ownerUid: activeUser.uid,
        ownerName: activeUser.displayName,
        ownerEmail: activeUser.email,
      );
    } else if (_users.containsKey(doc.ownerUid)) {
      final owner = _users[doc.ownerUid]!;
      docToInsert = doc.copyWith(
        ownerName: owner.displayName,
        ownerEmail: owner.email,
      );
    }

    if (enforceRls) {
      RlsPolicyEngine.assertCanInsertDocument(
        document: docToInsert,
        currentUserUid: _currentUserUid,
      );
    }

    // Nếu tài liệu chưa có storagePath nhưng có tên file thì khởi tạo đường dẫn Firebase Storage chuẩn
    if (docToInsert.storagePath.isEmpty && docToInsert.fileName.isNotEmpty) {
      final path = FirebaseStorageService.instance.buildStoragePath(
        ownerUid: docToInsert.ownerUid,
        subjectId: docToInsert.subjectId,
        documentId: docToInsert.id,
        fileName: docToInsert.fileName,
      );
      docToInsert = docToInsert.copyWith(storagePath: path);
    }

    _documents[docToInsert.id] = docToInsert;
    await SupabaseSyncService.instance.upsertDocumentToSupabase(docToInsert);
    _notifyAll();
  }

  @override
  Future<void> updateDocument(StudyDocument doc) async {
    final existing = _documents[doc.id];
    if (existing == null) {
      throw ArgumentError('Không tìm thấy tài liệu với ID: ${doc.id}');
    }
    if (!_subjects.containsKey(doc.subjectId)) {
      throw ArgumentError(
        'Môn học với ID ${doc.subjectId} không tồn tại trong hệ thống',
      );
    }

    if (enforceRls) {
      RlsPolicyEngine.assertCanUpdateDocument(
        existingDocument: existing,
        updatedDocument: doc,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
      );
    }

    final updatedDoc = doc.copyWith(
      ownerUid: existing.ownerUid,
      ownerName: existing.ownerName,
      ownerEmail: existing.ownerEmail,
      updatedAt: DateTime.now(),
    );
    _documents[doc.id] = updatedDoc;
    await SupabaseSyncService.instance.upsertDocumentToSupabase(updatedDoc);
    _notifyAll();
  }

  @override
  Future<void> deleteDocument(String id) async {
    final existing = _documents[id];
    if (existing == null) return;

    if (enforceRls) {
      RlsPolicyEngine.assertCanDeleteDocument(
        document: existing,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
      );
    }

    _documents.remove(id);
    // Cascade delete permissions trên bảng `permissions`
    _permissions.removeWhere((_, perm) => perm.documentId == id);
    // Xóa tệp vật lý trên Firebase Storage nếu có
    if (existing.isStoredOnFirebase) {
      await FirebaseStorageService.instance.deleteDocumentFile(existing.storagePath);
    }
    await SupabaseSyncService.instance.deleteDocumentFromSupabase(id);
    _notifyAll();
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final doc = _documents[id];
    if (doc != null) {
      if (enforceRls) {
        RlsPolicyEngine.assertCanUpdateDocument(
          existingDocument: doc,
          updatedDocument: doc,
          permissions: _permissions.values,
          currentUserUid: _currentUserUid,
        );
      }
      final updated = doc.copyWith(
        isFavorite: !doc.isFavorite,
        updatedAt: DateTime.now(),
      );
      _documents[id] = updated;
      await SupabaseSyncService.instance.upsertDocumentToSupabase(updated);
      _notifyAll();
    }
  }

  @override
  Future<void> updateDocumentStatus(String id, DocumentStatus newStatus) async {
    final doc = _documents[id];
    if (doc != null) {
      if (enforceRls) {
        RlsPolicyEngine.assertCanUpdateDocument(
          existingDocument: doc,
          updatedDocument: doc,
          permissions: _permissions.values,
          currentUserUid: _currentUserUid,
        );
      }
      final updated = doc.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      _documents[id] = updated;
      await SupabaseSyncService.instance.upsertDocumentToSupabase(updated);
      _notifyAll();
    }
  }

  // ================= PERMISSIONS & SHARING OPERATIONS (SUPABASE RLS) =================

  @override
  Stream<List<DocumentPermission>> watchPermissionsForDocument(String documentId) {
    return _permissionsController.stream.map((perms) {
      return perms.where((p) => p.documentId == documentId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }).asBroadcastStream(
      onListen: (_) {
        _permissionsController.add(_permissions.values.toList());
      },
    );
  }

  @override
  Future<List<DocumentPermission>> getPermissionsForDocument(String documentId) async {
    final doc = _documents[documentId];
    if (doc == null) return const [];

    if (enforceRls) {
      RlsPolicyEngine.assertCanSelectDocument(
        document: doc,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
      );
    }

    return _permissions.values
        .where((p) => p.documentId == documentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<DocumentPermission>> getAllPermissions() async {
    return _permissions.values.toList();
  }

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required PermissionLevel permissionLevel,
  }) async {
    final doc = _documents[documentId];
    if (doc == null) {
      throw ArgumentError('Không tìm thấy tài liệu cần chia sẻ: $documentId');
    }

    if (permissionLevel != PermissionLevel.viewer &&
        permissionLevel != PermissionLevel.editor) {
      throw ArgumentError('Cấp độ quyền chia sẻ chỉ có thể là viewer hoặc editor.');
    }

    // Kiểm tra RLS: Chỉ Owner của tài liệu mới được phép chia sẻ
    if (enforceRls) {
      RlsPolicyEngine.assertCanManagePermissions(
        document: doc,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
        operation: 'SHARE_INSERT',
      );
    }

    final normalizedEmail = targetEmail.trim().toLowerCase();
    if (normalizedEmail == doc.ownerEmail.trim().toLowerCase()) {
      throw ArgumentError('Không thể chia sẻ tài liệu cho chính Chủ sở hữu.');
    }

    // Tìm người dùng nhận chia sẻ trong bảng `users` (hoặc tự động khởi tạo hồ sơ chờ nếu là email Google mới)
    var targetUser = await getUserByEmail(normalizedEmail);
    if (targetUser == null) {
      final namePart = normalizedEmail.split('@').first;
      targetUser = AppUser(
        uid: 'uid_${const Uuid().v4().substring(0, 8)}',
        email: normalizedEmail,
        displayName: namePart,
        roleTitle: 'Thành viên được mời',
        department: 'Khoa CNTT',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      _users[targetUser.uid] = targetUser;
    }

    // Kiểm tra nếu đã chia sẻ trước đó thì cập nhật cấp độ quyền (Upsert)
    DocumentPermission? existingPerm;
    for (final p in _permissions.values) {
      if (p.documentId == documentId && p.sharedWithUid == targetUser.uid) {
        existingPerm = p;
        break;
      }
    }

    final now = DateTime.now();
    final DocumentPermission savedPerm;
    if (existingPerm != null) {
      savedPerm = existingPerm.copyWith(
        permissionLevel: permissionLevel,
        updatedAt: now,
      );
    } else {
      savedPerm = DocumentPermission(
        id: 'perm_${const Uuid().v4().substring(0, 8)}',
        documentId: documentId,
        sharedWithUid: targetUser.uid,
        sharedWithEmail: targetUser.email,
        sharedWithName: targetUser.displayName,
        permissionLevel: permissionLevel,
        grantedByUid: _currentUserUid ?? doc.ownerUid,
        createdAt: now,
        updatedAt: now,
      );
    }

    _permissions[savedPerm.id] = savedPerm;
    await SupabaseSyncService.instance.upsertPermissionToSupabase(savedPerm);
    _notifyAll();
    return savedPerm;
  }

  @override
  Future<DocumentPermission> updatePermissionLevel({
    required String permissionId,
    required PermissionLevel newLevel,
  }) async {
    final existing = _permissions[permissionId];
    if (existing == null) {
      throw ArgumentError('Không tìm thấy bản ghi quyền truy cập: $permissionId');
    }

    final doc = _documents[existing.documentId];
    if (doc == null) {
      throw ArgumentError('Không tìm thấy tài liệu liên kết');
    }

    if (enforceRls) {
      RlsPolicyEngine.assertCanManagePermissions(
        document: doc,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
        operation: 'PERMISSION_UPDATE',
      );
    }

    final updated = existing.copyWith(
      permissionLevel: newLevel,
      updatedAt: DateTime.now(),
    );
    _permissions[permissionId] = updated;
    await SupabaseSyncService.instance.upsertPermissionToSupabase(updated);
    _notifyAll();
    return updated;
  }

  @override
  Future<void> revokePermission(String permissionId) async {
    final existing = _permissions[permissionId];
    if (existing == null) return;

    final doc = _documents[existing.documentId];
    if (doc != null && enforceRls) {
      // Cho phép Owner thu hồi quyền hoặc người được chia sẻ tự rời khỏi tài liệu
      final isSelfLeaving = existing.sharedWithUid == _currentUserUid;
      if (!isSelfLeaving) {
        RlsPolicyEngine.assertCanManagePermissions(
          document: doc,
          permissions: _permissions.values,
          currentUserUid: _currentUserUid,
          operation: 'PERMISSION_DELETE',
        );
      }
    }

    _permissions.remove(permissionId);
    await SupabaseSyncService.instance.deletePermissionFromSupabase(permissionId);
    _notifyAll();
  }

  // ================= FIREBASE STORAGE UPLOAD & SUPABASE LINKING =================

  @override
  Future<StorageUploadResult> uploadFileToStorage({
    required String documentId,
    required String subjectId,
    required String fileName,
    required Uint8List bytes,
    required String fileType,
  }) async {
    final existingDoc = _documents[documentId];
    final ownerUid = existingDoc?.ownerUid ?? (_currentUserUid ?? 'uid_user_1');

    if (existingDoc != null && enforceRls) {
      RlsPolicyEngine.assertCanUpdateDocument(
        existingDocument: existingDoc,
        updatedDocument: existingDoc,
        permissions: _permissions.values,
        currentUserUid: _currentUserUid,
      );
    }

    final result = await FirebaseStorageService.instance.uploadDocumentFile(
      ownerUid: ownerUid,
      subjectId: subjectId,
      documentId: documentId,
      fileName: fileName,
      bytes: bytes,
      fileType: fileType,
      uploadedByUid: _currentUserUid ?? ownerUid,
    );

    // Nếu tài liệu đã tồn tại trong bảng `documents` trên Supabase thì tự động cập nhật liên kết
    if (existingDoc != null) {
      final updatedDoc = existingDoc.copyWith(
        fileUrl: result.downloadUrl,
        storagePath: result.storagePath,
        fileName: result.fileName,
        fileType: result.fileType,
        fileSizeBytes: result.fileSizeBytes,
        updatedAt: DateTime.now(),
      );
      _documents[documentId] = updatedDoc;
      await SupabaseSyncService.instance.upsertDocumentToSupabase(updatedDoc);
      _notifyAll();
    }

    return result;
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
      // Xóa tầng liên kết (Cascade Delete): xóa các tài liệu và quyền thuộc môn học này
      final removedDocIds = _documents.values
          .where((doc) => doc.subjectId == id)
          .map((doc) => doc.id)
          .toSet();
      _documents.removeWhere((key, doc) => doc.subjectId == id);
      _permissions.removeWhere((key, perm) => removedDocIds.contains(perm.documentId));
      _notifyAll();
    }
  }

  @override
  Future<void> resetToSampleData() async {
    _documents.clear();
    _subjects.clear();
    _permissions.clear();
    _loadSampleData();
  }

  @override
  Future<void> clearAll() async {
    _documents.clear();
    _subjects.clear();
    _permissions.clear();
    _notifyAll();
  }

  @override
  void dispose() {
    _docsController.close();
    _subjectsController.close();
    _currentUserController.close();
    _usersController.close();
    _permissionsController.close();
  }
}
