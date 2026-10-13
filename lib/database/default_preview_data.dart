import '../struct/models.dart';

/// Dữ liệu mẫu khởi tạo ứng dụng (Sample / Preview Data Generator)
/// Bao gồm 4 tài khoản Google (Firebase Auth), 4 môn học, 7 tài liệu (Firebase Storage)
/// và ma trận phân quyền chia sẻ (Supabase Permissions & RLS).
class DefaultPreviewData {
  /// Danh sách 4 tài khoản Google mẫu phục vụ kiểm thử phân quyền đa tài khoản (Multi-Account RLS)
  static List<AppUser> getSampleUsers() {
    final now = DateTime.now();
    return [
      AppUser(
        uid: 'uid_user_1',
        email: 'an.nguyen@edu.vn',
        displayName: 'TS. Nguyễn Văn An',
        photoUrl: 'https://lh3.googleusercontent.com/a/default-user-an',
        roleTitle: 'Giảng viên (Chủ sở hữu chính)',
        department: 'Bộ môn Kỹ thuật Phần mềm',
        avatarColorValue: 0xFF1E88E5, // Blue
        createdAt: now.subtract(const Duration(days: 60)),
        lastLoginAt: now,
      ),
      AppUser(
        uid: 'uid_user_2',
        email: 'binh.tran@edu.vn',
        displayName: 'ThS. Trần Thị Bình',
        photoUrl: 'https://lh3.googleusercontent.com/a/default-user-binh',
        roleTitle: 'Trợ giảng (Quyền Editor)',
        department: 'Bộ môn Hệ thống Thông tin',
        avatarColorValue: 0xFF00897B, // Teal
        createdAt: now.subtract(const Duration(days: 45)),
        lastLoginAt: now.subtract(const Duration(hours: 2)),
      ),
      AppUser(
        uid: 'uid_user_3',
        email: 'cuong.le@edu.vn',
        displayName: 'Lê Hoàng Cường',
        photoUrl: 'https://lh3.googleusercontent.com/a/default-user-cuong',
        roleTitle: 'Sinh viên K18 (Quyền Viewer)',
        department: 'Khoa Công nghệ Thông tin',
        avatarColorValue: 0xFF8E24AA, // Purple
        createdAt: now.subtract(const Duration(days: 30)),
        lastLoginAt: now.subtract(const Duration(hours: 5)),
      ),
      AppUser(
        uid: 'uid_user_4',
        email: 'dung.pham@edu.vn',
        displayName: 'Phạm Minh Dũng',
        photoUrl: 'https://lh3.googleusercontent.com/a/default-user-dung',
        roleTitle: 'Sinh viên lớp ngoài (Kiểm thử chặn RLS)',
        department: 'Khoa Khoa học Máy tính',
        avatarColorValue: 0xFFE53935, // Red
        createdAt: now.subtract(const Duration(days: 15)),
        lastLoginAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }

  static final List<Subject> sampleSubjects = [
    Subject(
      id: 'sub_se301',
      code: 'SE301',
      name: 'Kiến trúc Phần mềm',
      lecturer: 'TS. Nguyễn Văn An',
      colorValue: 0xFF1E88E5, // Blue
      iconName: 'architecture',
      semester: 'HK1 2026-2027',
      creditCount: 4,
      ownerUid: 'uid_user_1',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Subject(
      id: 'sub_se346',
      code: 'SE346',
      name: 'Phát triển Ứng dụng Di động',
      lecturer: 'ThS. Trần Thị Bình',
      colorValue: 0xFF7E57C2, // Purple
      iconName: 'phone_android',
      semester: 'HK1 2026-2027',
      creditCount: 3,
      ownerUid: 'uid_user_2',
      createdAt: DateTime.now().subtract(const Duration(days: 28)),
    ),
    Subject(
      id: 'sub_cs204',
      code: 'CS204',
      name: 'Cơ sở Dữ liệu Phân tán',
      lecturer: 'PGS.TS. Lê Văn C',
      colorValue: 0xFF00BFA5, // Teal
      iconName: 'storage',
      semester: 'HK1 2026-2027',
      creditCount: 3,
      ownerUid: 'uid_user_1',
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Subject(
      id: 'sub_ai402',
      code: 'AI402',
      name: 'Trí tuệ Nhân tạo Ứng dụng',
      lecturer: 'TS. Hoàng Đức D',
      colorValue: 0xFFFF7043, // Deep Orange
      iconName: 'psychology',
      semester: 'HK1 2026-2027',
      creditCount: 4,
      ownerUid: 'uid_user_1',
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
  ];

  static List<StudyDocument> getSampleDocuments() {
    final now = DateTime.now();

    return [
      StudyDocument(
        id: 'doc_01',
        title: 'Slide Bài giảng Chương 3: Kiến trúc Phân tầng & Cashew Architecture',
        description:
            'Tài liệu chi tiết về phân tách UI, Logic (Struct), Data Layer và cơ chế Reactive Streams.',
        subjectId: 'sub_se301',
        ownerUid: 'uid_user_1',
        ownerName: 'TS. Nguyễn Văn An',
        ownerEmail: 'an.nguyen@edu.vn',
        type: DocumentType.lecture,
        status: DocumentStatus.completed,
        priority: Priority.high,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_1%2Fsubjects%2Fsub_se301%2Fdocuments%2Fdoc_01%2Farchitecture-cashew-ch3.pdf?alt=media',
        storagePath:
            'users/uid_user_1/subjects/sub_se301/documents/doc_01/architecture-cashew-ch3.pdf',
        fileName: 'architecture-cashew-ch3.pdf',
        fileType: 'PDF',
        fileSizeBytes: 4850000, // ~4.6 MB
        dueDate: null,
        isFavorite: true,
        tags: ['architecture', 'cashew', 'slides', 'solid'],
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      StudyDocument(
        id: 'doc_02',
        title: 'Bài tập lớn: Thiết kế & Triển khai Ứng dụng Quản lý Tài liệu',
        description:
            'Yêu cầu: áp dụng đúng chuẩn kiến trúc Cashew, tích hợp Firebase + Supabase RLS, kiểm thử đa tài khoản.',
        subjectId: 'sub_se301',
        ownerUid: 'uid_user_1',
        ownerName: 'TS. Nguyễn Văn An',
        ownerEmail: 'an.nguyen@edu.vn',
        type: DocumentType.assignment,
        status: DocumentStatus.inProgress,
        priority: Priority.urgent,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_1%2Fsubjects%2Fsub_se301%2Fdocuments%2Fdoc_02%2Fassignment-cashew-spec.pdf?alt=media',
        storagePath:
            'users/uid_user_1/subjects/sub_se301/documents/doc_02/assignment-cashew-spec.pdf',
        fileName: 'assignment-cashew-spec.pdf',
        fileType: 'PDF',
        fileSizeBytes: 1250000, // ~1.2 MB
        dueDate: now.add(const Duration(days: 3, hours: 4)),
        isFavorite: true,
        tags: ['assignment', 'cashew', 'midterm', 'flutter', 'cloud'],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      StudyDocument(
        id: 'doc_03',
        title: 'Slide Bài giảng 05: Flutter State Management & Provider Pattern',
        description:
            'Tổng quan về Provider, ChangeNotifier, ValueListenable và StreamBuilder.',
        subjectId: 'sub_se346',
        ownerUid: 'uid_user_2',
        ownerName: 'ThS. Trần Thị Bình',
        ownerEmail: 'binh.tran@edu.vn',
        type: DocumentType.lecture,
        status: DocumentStatus.inProgress,
        priority: Priority.medium,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_2%2Fsubjects%2Fsub_se346%2Fdocuments%2Fdoc_03%2Fflutter-provider-slides.pptx?alt=media',
        storagePath:
            'users/uid_user_2/subjects/sub_se346/documents/doc_03/flutter-provider-slides.pptx',
        fileName: 'flutter-provider-slides.pptx',
        fileType: 'PPTX',
        fileSizeBytes: 3420000,
        dueDate: null,
        isFavorite: false,
        tags: ['flutter', 'provider', 'statemanagement'],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      StudyDocument(
        id: 'doc_04',
        title: 'Bài tập thực hành tuần 6: Tạo giao diện Responsive với Material 3',
        description:
            'Xây dựng giao diện danh sách thẻ tài liệu tự co giãn và bottom sheet bộ lọc.',
        subjectId: 'sub_se346',
        ownerUid: 'uid_user_1',
        ownerName: 'TS. Nguyễn Văn An',
        ownerEmail: 'an.nguyen@edu.vn',
        type: DocumentType.assignment,
        status: DocumentStatus.pending,
        priority: Priority.high,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_1%2Fsubjects%2Fsub_se346%2Fdocuments%2Fdoc_04%2Fmaterial3_exercise.zip?alt=media',
        storagePath:
            'users/uid_user_1/subjects/sub_se346/documents/doc_04/material3_exercise.zip',
        fileName: 'material3_exercise.zip',
        fileType: 'ZIP',
        fileSizeBytes: 15400000, // 15.4 MB
        dueDate: now.add(const Duration(days: 5, hours: 12)),
        isFavorite: false,
        tags: ['homework', 'ui', 'material3'],
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      StudyDocument(
        id: 'doc_05',
        title: 'Tài liệu tham khảo: Designing Data-Intensive Applications (Martin Kleppmann)',
        description: 'Chương 5 & 6: Replication, Partitioning và Distributed Consensus.',
        subjectId: 'sub_cs204',
        ownerUid: 'uid_user_1',
        ownerName: 'TS. Nguyễn Văn An',
        ownerEmail: 'an.nguyen@edu.vn',
        type: DocumentType.reference,
        status: DocumentStatus.completed,
        priority: Priority.medium,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_1%2Fsubjects%2Fsub_cs204%2Fdocuments%2Fdoc_05%2Fddia-ch5-ch6.pdf?alt=media',
        storagePath:
            'users/uid_user_1/subjects/sub_cs204/documents/doc_05/ddia-ch5-ch6.pdf',
        fileName: 'ddia-ch5-ch6.pdf',
        fileType: 'PDF',
        fileSizeBytes: 24500000, // 24.5 MB
        dueDate: null,
        isFavorite: true,
        tags: ['database', 'distributed', 'book', 'reference'],
        createdAt: now.subtract(const Duration(days: 22)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      StudyDocument(
        id: 'doc_06',
        title: 'Đề cương ôn tập & Bộ đề thi thử Giữa kỳ Trí tuệ Nhân tạo',
        description:
            'Bao gồm 50 câu hỏi trắc nghiệm và 3 bài toán A* Search, Minimax Alpha-Beta.',
        subjectId: 'sub_ai402',
        ownerUid: 'uid_user_1',
        ownerName: 'TS. Nguyễn Văn An',
        ownerEmail: 'an.nguyen@edu.vn',
        type: DocumentType.exam,
        status: DocumentStatus.pending,
        priority: Priority.urgent,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_1%2Fsubjects%2Fsub_ai402%2Fdocuments%2Fdoc_06%2Fmidterm-review-2026.pdf?alt=media',
        storagePath:
            'users/uid_user_1/subjects/sub_ai402/documents/doc_06/midterm-review-2026.pdf',
        fileName: 'midterm-review-2026.pdf',
        fileType: 'PDF',
        fileSizeBytes: 3100000,
        dueDate: now.add(const Duration(days: 2)),
        isFavorite: true,
        tags: ['exam', 'review', 'ai', 'midterm'],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      StudyDocument(
        id: 'doc_07',
        title: 'Bài tập nhóm: Thuật toán Tối ưu hóa bầy đàn (PSO Algorithm)',
        description:
            'Cài đặt thuật toán bằng Python/Dart và so sánh tốc độ hội tụ với Genetic Algorithm.',
        subjectId: 'sub_ai402',
        ownerUid: 'uid_user_3',
        ownerName: 'Lê Hoàng Cường',
        ownerEmail: 'cuong.le@edu.vn',
        type: DocumentType.assignment,
        status: DocumentStatus.completed,
        priority: Priority.low,
        fileUrl:
            'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/users%2Fuid_user_3%2Fsubjects%2Fsub_ai402%2Fdocuments%2Fdoc_07%2Fpso-experiment-report.docx?alt=media',
        storagePath:
            'users/uid_user_3/subjects/sub_ai402/documents/doc_07/pso-experiment-report.docx',
        fileName: 'pso-experiment-report.docx',
        fileType: 'DOCX',
        fileSizeBytes: 1840000,
        dueDate: now.subtract(const Duration(days: 2)),
        isFavorite: false,
        tags: ['pso', 'ai', 'algorithm', 'python'],
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  /// Danh sách quyền chia sẻ mẫu trên bảng `permissions` của Supabase
  static List<DocumentPermission> getSamplePermissions() {
    final now = DateTime.now();
    return [
      // doc_01 (Owner: uid_user_1) -> Chia sẻ Editor cho uid_user_2, Viewer cho uid_user_3
      DocumentPermission(
        id: 'perm_01',
        documentId: 'doc_01',
        sharedWithUid: 'uid_user_2',
        sharedWithEmail: 'binh.tran@edu.vn',
        sharedWithName: 'ThS. Trần Thị Bình',
        permissionLevel: PermissionLevel.editor,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      DocumentPermission(
        id: 'perm_02',
        documentId: 'doc_01',
        sharedWithUid: 'uid_user_3',
        sharedWithEmail: 'cuong.le@edu.vn',
        sharedWithName: 'Lê Hoàng Cường',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),

      // doc_02 (Owner: uid_user_1) -> Chia sẻ Editor cho uid_user_2, Viewer cho uid_user_3
      DocumentPermission(
        id: 'perm_03',
        documentId: 'doc_02',
        sharedWithUid: 'uid_user_2',
        sharedWithEmail: 'binh.tran@edu.vn',
        sharedWithName: 'ThS. Trần Thị Bình',
        permissionLevel: PermissionLevel.editor,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      DocumentPermission(
        id: 'perm_04',
        documentId: 'doc_02',
        sharedWithUid: 'uid_user_3',
        sharedWithEmail: 'cuong.le@edu.vn',
        sharedWithName: 'Lê Hoàng Cường',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),

      // doc_03 (Owner: uid_user_2) -> Chia sẻ Editor cho uid_user_1, Viewer cho uid_user_3
      DocumentPermission(
        id: 'perm_05',
        documentId: 'doc_03',
        sharedWithUid: 'uid_user_1',
        sharedWithEmail: 'an.nguyen@edu.vn',
        sharedWithName: 'TS. Nguyễn Văn An',
        permissionLevel: PermissionLevel.editor,
        grantedByUid: 'uid_user_2',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      DocumentPermission(
        id: 'perm_06',
        documentId: 'doc_03',
        sharedWithUid: 'uid_user_3',
        sharedWithEmail: 'cuong.le@edu.vn',
        sharedWithName: 'Lê Hoàng Cường',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_2',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),

      // doc_04 (Owner: uid_user_1) -> Chia sẻ Editor cho uid_user_2
      DocumentPermission(
        id: 'perm_07',
        documentId: 'doc_04',
        sharedWithUid: 'uid_user_2',
        sharedWithEmail: 'binh.tran@edu.vn',
        sharedWithName: 'ThS. Trần Thị Bình',
        permissionLevel: PermissionLevel.editor,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),

      // doc_05 (Owner: uid_user_1) -> Chia sẻ Viewer cho uid_user_4
      DocumentPermission(
        id: 'perm_08',
        documentId: 'doc_05',
        sharedWithUid: 'uid_user_4',
        sharedWithEmail: 'dung.pham@edu.vn',
        sharedWithName: 'Phạm Minh Dũng',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),

      // doc_06 (Owner: uid_user_1) -> Chia sẻ Viewer cho uid_user_3
      DocumentPermission(
        id: 'perm_09',
        documentId: 'doc_06',
        sharedWithUid: 'uid_user_3',
        sharedWithEmail: 'cuong.le@edu.vn',
        sharedWithName: 'Lê Hoàng Cường',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_1',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),

      // doc_07 (Owner: uid_user_3) -> Chia sẻ Editor cho uid_user_1, Viewer cho uid_user_2
      DocumentPermission(
        id: 'perm_10',
        documentId: 'doc_07',
        sharedWithUid: 'uid_user_1',
        sharedWithEmail: 'an.nguyen@edu.vn',
        sharedWithName: 'TS. Nguyễn Văn An',
        permissionLevel: PermissionLevel.editor,
        grantedByUid: 'uid_user_3',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      DocumentPermission(
        id: 'perm_11',
        documentId: 'doc_07',
        sharedWithUid: 'uid_user_2',
        sharedWithEmail: 'binh.tran@edu.vn',
        sharedWithName: 'ThS. Trần Thị Bình',
        permissionLevel: PermissionLevel.viewer,
        grantedByUid: 'uid_user_3',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}
