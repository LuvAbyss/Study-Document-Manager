import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/cloud/auth_service.dart';
import 'package:study_document_manager/cloud/rls_policy_engine.dart';
import 'package:study_document_manager/cloud/storage_service.dart';
import 'package:study_document_manager/database/app_database.dart';
import 'package:study_document_manager/database/database_global.dart';
import 'package:study_document_manager/struct/models.dart';

void main() {
  group(
    'Kiểm thử Hệ sinh thái Cloud, Phân quyền Chia sẻ & RLS trên Đa Tài khoản (>= 3 Tài khoản)',
    () {
      late AppDatabase db;
      late CloudAuthService authService;

      // Định danh 4 tài khoản kiểm thử:
      // 1. uid_user_1: an.nguyen@edu.vn (Giảng viên - Chủ sở hữu)
      // 2. uid_user_2: binh.tran@edu.vn (Trợ giảng - Quyền Editor)
      // 3. uid_user_3: cuong.le@edu.vn (Sinh viên - Quyền Viewer)
      // 4. uid_user_4: dung.pham@edu.vn (Sinh viên lớp ngoài - Không được chia sẻ)
      const String user1OwnerUid = 'uid_user_1';
      const String user2EditorUid = 'uid_user_2';
      const String user3ViewerUid = 'uid_user_3';
      const String user4OutsiderUid = 'uid_user_4';

      setUp(() {
        db = AppDatabase(
          populateSampleData: false,
          enforceRls: true,
          initialUserUid: user1OwnerUid,
        );
        database = db;
        authService = CloudAuthService();
      });

      tearDown(() {
        authService.dispose();
        db.dispose();
      });

      test(
        '1. Xác thực Google (Firebase Auth) và đồng bộ 4 tài khoản người dùng trên bảng `users` (Supabase)',
        () async {
          final users = await db.getAllUsers();
          expect(users.length, greaterThanOrEqualTo(4));

          // Mặc định đăng nhập Tài khoản 1 (TS. Nguyễn Văn An)
          expect(authService.currentUser?.uid, user1OwnerUid);
          expect(authService.currentUser?.email, 'an.nguyen@edu.vn');

          // Chuyển sang Tài khoản 2 (ThS. Trần Thị Bình)
          final user2 = await authService.switchAccount(user2EditorUid);
          expect(user2.email, 'binh.tran@edu.vn');
          expect(db.currentUserUid, user2EditorUid);

          // Kiểm tra RLS trên bảng `users`: Tài khoản 2 không được phép sửa hồ sơ của Tài khoản 1
          final user1Profile = (await db.getUserByUid(user1OwnerUid))!;
          expect(
            () => db.upsertUser(user1Profile.copyWith(displayName: 'Bị sửa trái phép')),
            throwsA(isA<RlsAccessDeniedException>()),
          );

          // Chuyển sang Tài khoản 3 (Lê Hoàng Cường)
          final user3 = await authService.switchAccount(user3ViewerUid);
          expect(user3.email, 'cuong.le@edu.vn');
          expect(db.currentUserUid, user3ViewerUid);
        },
      );

      test(
        '2. Cấu trúc lưu trữ tệp vật lý trên Firebase Storage và kết nối với bảng `documents` trên Supabase',
        () async {
          await db.insertSubject(
            Subject(
              id: 'sub_cloud',
              code: 'CLOUD101',
              name: 'Điện toán Đám mây',
              ownerUid: user1OwnerUid,
              createdAt: DateTime.now(),
            ),
          );

          final doc = StudyDocument(
            id: 'doc_storage_01',
            title: 'Bài giảng Kiến trúc Cloud Firebase & Supabase',
            subjectId: 'sub_cloud',
            ownerUid: user1OwnerUid,
            type: DocumentType.lecture,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await db.insertDocument(doc);

          final fileBytes = Uint8List.fromList(
            utf8.encode('PDF_BINARY_CONTENT_FOR_CLOUD_STORAGE_TEST'),
          );

          // Tải tệp vật lý lên Firebase Storage và gắn kết với bản ghi trên Supabase
          final uploadResult = await db.uploadFileToStorage(
            documentId: 'doc_storage_01',
            subjectId: 'sub_cloud',
            fileName: 'cloud_architecture_lecture.pdf',
            bytes: fileBytes,
            fileType: 'PDF',
          );

          // Kiểm tra cấu trúc đường dẫn phân cấp chuẩn trên Firebase Storage
          expect(
            uploadResult.storagePath,
            'users/uid_user_1/subjects/sub_cloud/documents/doc_storage_01/cloud_architecture_lecture.pdf',
          );
          expect(
            FirebaseStorageService.instance.fileExists(uploadResult.storagePath),
            isTrue,
          );
          expect(uploadResult.fileSizeBytes, fileBytes.length);

          // Kiểm tra thông tin tệp đã được đồng bộ vào bảng `documents`
          final updatedDoc = await db.getDocumentById('doc_storage_01');
          expect(updatedDoc, isNotNull);
          expect(updatedDoc!.storagePath, uploadResult.storagePath);
          expect(updatedDoc.fileUrl, uploadResult.downloadUrl);
          expect(updatedDoc.fileName, 'cloud_architecture_lecture.pdf');
          expect(updatedDoc.fileSizeBytes, fileBytes.length);
        },
      );

      test(
        '3. Luồng phân quyền RLS toàn diện trên 4 tài khoản: Cô lập dữ liệu, Chia sẻ Viewer/Editor và Toàn vẹn dữ liệu',
        () async {
          // Bước 1: Tài khoản 1 (Owner: an.nguyen@edu.vn) tạo môn học và tài liệu riêng tư
          await authService.switchAccount(user1OwnerUid);
          await db.insertSubject(
            Subject(
              id: 'sub_sec',
              code: 'SEC401',
              name: 'An toàn và Bảo mật Hệ thống',
              ownerUid: user1OwnerUid,
              createdAt: DateTime.now(),
            ),
          );

          final privateDoc = StudyDocument(
            id: 'doc_rls_matrix',
            title: 'Đề thi kết thúc học phần An toàn Thông tin',
            description: 'Bản gốc do Giảng viên Nguyễn Văn An biên soạn.',
            subjectId: 'sub_sec',
            ownerUid: user1OwnerUid,
            type: DocumentType.exam,
            priority: Priority.urgent,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await db.insertDocument(privateDoc);

          // Bước 2: Kiểm tra cô lập RLS khi chưa chia sẻ
          // Tài khoản 2, 3, 4 đều KHÔNG được phép nhìn thấy tài liệu riêng tư của Tài khoản 1
          for (final otherUid in [user2EditorUid, user3ViewerUid, user4OutsiderUid]) {
            await authService.switchAccount(otherUid);
            expect(await db.getAllDocuments(), isEmpty);
            expect(await db.getDocumentById('doc_rls_matrix'), isNull);
            expect(
              db.getEffectivePermission('doc_rls_matrix'),
              PermissionLevel.none,
            );
          }

          // Bước 3: Tài khoản 1 chia sẻ quyền VIEWER cho Tài khoản 3 (cuong.le@edu.vn)
          // và quyền EDITOR cho Tài khoản 2 (binh.tran@edu.vn)
          await authService.switchAccount(user1OwnerUid);

          final viewerPerm = await db.shareDocument(
            documentId: 'doc_rls_matrix',
            targetEmail: 'cuong.le@edu.vn',
            permissionLevel: PermissionLevel.viewer,
          );
          expect(viewerPerm.sharedWithUid, user3ViewerUid);
          expect(viewerPerm.permissionLevel, PermissionLevel.viewer);

          final editorPerm = await db.shareDocument(
            documentId: 'doc_rls_matrix',
            targetEmail: 'binh.tran@edu.vn',
            permissionLevel: PermissionLevel.editor,
          );
          expect(editorPerm.sharedWithUid, user2EditorUid);
          expect(editorPerm.permissionLevel, PermissionLevel.editor);

          // Bước 4: Kiểm chứng dưới góc nhìn Tài khoản 3 (Sinh viên - Quyền VIEWER)
          await authService.switchAccount(user3ViewerUid);
          expect(
            db.getEffectivePermission('doc_rls_matrix'),
            PermissionLevel.viewer,
          );

          // Tài khoản 3 có thể XEM và TÌM KIẾM tài liệu
          final docsForUser3 = await db.getAllDocuments();
          expect(docsForUser3.length, 1);
          expect(docsForUser3.first.title, contains('An toàn Thông tin'));

          // Nhưng Tài khoản 3 (Viewer) bị RLS CHẶN khi cố tình SỬA, XÓA hoặc CHIA SẺ
          expect(
            () => db.updateDocument(
              docsForUser3.first.copyWith(title: 'Sinh viên sửa đề thi trái phép'),
            ),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.updateDocumentStatus('doc_rls_matrix', DocumentStatus.completed),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.deleteDocument('doc_rls_matrix'),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.shareDocument(
              documentId: 'doc_rls_matrix',
              targetEmail: 'dung.pham@edu.vn',
              permissionLevel: PermissionLevel.viewer,
            ),
            throwsA(isA<RlsAccessDeniedException>()),
          );

          // Bước 5: Kiểm chứng dưới góc nhìn Tài khoản 2 (Trợ giảng - Quyền EDITOR)
          await authService.switchAccount(user2EditorUid);
          expect(
            db.getEffectivePermission('doc_rls_matrix'),
            PermissionLevel.editor,
          );

          // Tài khoản 2 (Editor) ĐƯỢC PHÉP cập nhật nội dung tài liệu và tải tệp mới
          final docForUser2 = (await db.getDocumentById('doc_rls_matrix'))!;
          await db.updateDocument(
            docForUser2.copyWith(
              title: 'Đề thi An toàn Thông tin (Đã phản biện bởi Trợ giảng Bình)',
              description: 'Đã bổ sung câu hỏi tự luận về Supabase RLS.',
              status: DocumentStatus.inProgress,
            ),
          );

          // Nhưng Tài khoản 2 (Editor) bị RLS CHẶN nếu cố tình chiếm quyền sở hữu (đổi ownerUid),
          // XÓA tài liệu hoặc THAY ĐỔI quyền chia sẻ
          expect(
            () => db.updateDocument(
              docForUser2.copyWith(ownerUid: user2EditorUid),
            ),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.deleteDocument('doc_rls_matrix'),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.shareDocument(
              documentId: 'doc_rls_matrix',
              targetEmail: 'dung.pham@edu.vn',
              permissionLevel: PermissionLevel.viewer,
            ),
            throwsA(isA<RlsAccessDeniedException>()),
          );
          expect(
            () => db.revokePermission(viewerPerm.id),
            throwsA(isA<RlsAccessDeniedException>()),
          );

          // Bước 6: Kiểm tra tính toàn vẹn dữ liệu (Data Integrity) trên các tài khoản khác
          // Tài khoản 4 (Outsider) vẫn bị chặn hoàn toàn
          await authService.switchAccount(user4OutsiderUid);
          expect(await db.getDocumentById('doc_rls_matrix'), isNull);

          // Tài khoản 3 (Viewer) và Tài khoản 1 (Owner) thấy đúng nội dung do Tài khoản 2 vừa cập nhật,
          // và thông tin Chủ sở hữu gốc vẫn giữ nguyên là Tài khoản 1 (uid_user_1)
          await authService.switchAccount(user3ViewerUid);
          final syncedDocUser3 = (await db.getDocumentById('doc_rls_matrix'))!;
          expect(
            syncedDocUser3.title,
            'Đề thi An toàn Thông tin (Đã phản biện bởi Trợ giảng Bình)',
          );
          expect(syncedDocUser3.ownerUid, user1OwnerUid);
          expect(syncedDocUser3.ownerEmail, 'an.nguyen@edu.vn');

          // Bước 7: Chủ sở hữu (Tài khoản 1) thu hồi quyền của Tài khoản 3 và xóa tài liệu
          await authService.switchAccount(user1OwnerUid);
          await db.revokePermission(viewerPerm.id);

          // Xác nhận Tài khoản 3 mất quyền truy cập ngay sau khi bị thu hồi
          await authService.switchAccount(user3ViewerUid);
          expect(await db.getDocumentById('doc_rls_matrix'), isNull);

          // Tài khoản 1 xóa hoàn toàn tài liệu -> Cascade xóa sạch permissions
          await authService.switchAccount(user1OwnerUid);
          await db.deleteDocument('doc_rls_matrix');
          expect(await db.getDocumentById('doc_rls_matrix'), isNull);
          expect(await db.getAllPermissions(), isEmpty);
        },
      );
    },
  );
}
