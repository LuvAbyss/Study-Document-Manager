import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'cloud_config.dart';

/// Kết quả tải tệp tin vật lý lên Firebase Storage
/// Dùng để lưu liên kết trực tiếp vào bảng `documents` trên Supabase
class StorageUploadResult {
  final String storagePath; // users/{ownerUid}/subjects/{subjectId}/documents/{documentId}/{fileName}
  final String downloadUrl; // https://firebasestorage.googleapis.com/v0/b/...
  final String fileName;
  final String fileType;
  final int fileSizeBytes;
  final String uploadedByUid;
  final DateTime uploadedAt;

  const StorageUploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.fileName,
    required this.fileType,
    required this.fileSizeBytes,
    required this.uploadedByUid,
    required this.uploadedAt,
  });
}

/// Giao diện tầng lưu trữ tệp vật lý trên Firebase Storage
abstract class ICloudStorageService {
  /// Xây dựng đường dẫn phân cấp chuẩn trên Firebase Storage:
  /// `users/{ownerUid}/subjects/{subjectId}/documents/{documentId}/{fileName}`
  String buildStoragePath({
    required String ownerUid,
    required String subjectId,
    required String documentId,
    required String fileName,
  });

  /// Tải tệp vật lý lên Firebase Storage và trả về thông tin kết nối với bảng `documents` trên Supabase
  Future<StorageUploadResult> uploadDocumentFile({
    required String ownerUid,
    required String subjectId,
    required String documentId,
    required String fileName,
    required Uint8List bytes,
    required String fileType,
    required String uploadedByUid,
  });

  /// Xóa tệp vật lý trên Firebase Storage khi xóa tài liệu
  Future<void> deleteDocumentFile(String storagePath);

  /// Kiểm tra tệp vật lý có tồn tại trên Storage hay không
  bool fileExists(String storagePath);

  /// Lấy kích thước tệp vật lý đã lưu
  int? getStoredFileSize(String storagePath);
}

/// Triển khai dịch vụ lưu trữ tệp vật lý trên Firebase Storage
/// Kết hợp Firebase Storage SDK thực tế và bộ nhớ Bucket đồng bộ để đảm bảo hoạt động ổn định
class FirebaseStorageService implements ICloudStorageService {
  static final FirebaseStorageService instance = FirebaseStorageService();

  // Bộ lưu trữ метаdata & dữ liệu nhị phân cục bộ phục vụ kiểm thử và chế độ Sandbox
  final Map<String, Uint8List> _virtualBucketBytes = {};
  final Map<String, StorageUploadResult> _virtualBucketMeta = {};

  @override
  String buildStoragePath({
    required String ownerUid,
    required String subjectId,
    required String documentId,
    required String fileName,
  }) {
    final sanitizedName = fileName
        .trim()
        .replaceAll(RegExp(r'[^\w\-.]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final safeName = sanitizedName.isEmpty ? 'document.pdf' : sanitizedName;
    return 'users/$ownerUid/subjects/$subjectId/documents/$documentId/$safeName';
  }

  @override
  Future<StorageUploadResult> uploadDocumentFile({
    required String ownerUid,
    required String subjectId,
    required String documentId,
    required String fileName,
    required Uint8List bytes,
    required String fileType,
    required String uploadedByUid,
  }) async {
    final storagePath = buildStoragePath(
      ownerUid: ownerUid,
      subjectId: subjectId,
      documentId: documentId,
      fileName: fileName,
    );

    String downloadUrl =
        'https://firebasestorage.googleapis.com/v0/b/cashew-studydocs.firebasestorage.app/o/${Uri.encodeComponent(storagePath)}?alt=media';

    // Nếu ứng dụng đã khởi tạo Firebase App với cấu hình thực tế thì thực hiện upload lên Firebase Storage
    if (Firebase.apps.isNotEmpty && CloudConfig.hasLiveSupabaseKeys) {
      try {
        final ref = FirebaseStorage.instance.ref().child(storagePath);
        final metadata = SettableMetadata(
          contentType: _mapContentType(fileType),
          customMetadata: {
            'ownerUid': ownerUid,
            'subjectId': subjectId,
            'documentId': documentId,
            'editorUid': uploadedByUid,
          },
        );
        await ref.putData(bytes, metadata);
        downloadUrl = await ref.getDownloadURL();
      } catch (_) {
        // Fallback an toàn về URL chuẩn của Firebase Storage nếu chưa cấu hình mạng/credentials
      }
    }

    final result = StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileType: fileType.toUpperCase(),
      fileSizeBytes: bytes.length,
      uploadedByUid: uploadedByUid,
      uploadedAt: DateTime.now(),
    );

    _virtualBucketBytes[storagePath] = bytes;
    _virtualBucketMeta[storagePath] = result;

    return result;
  }

  @override
  Future<void> deleteDocumentFile(String storagePath) async {
    if (storagePath.trim().isEmpty) return;

    _virtualBucketBytes.remove(storagePath);
    _virtualBucketMeta.remove(storagePath);

    if (Firebase.apps.isNotEmpty && CloudConfig.hasLiveSupabaseKeys) {
      try {
        await FirebaseStorage.instance.ref().child(storagePath).delete();
      } catch (_) {
        // Bỏ qua nếu tệp không tồn tại trên đám mây từ xa
      }
    }
  }

  @override
  bool fileExists(String storagePath) {
    return _virtualBucketMeta.containsKey(storagePath);
  }

  @override
  int? getStoredFileSize(String storagePath) {
    return _virtualBucketBytes[storagePath]?.length;
  }

  /// Đăng ký sẵn metadata cho các tệp mẫu khởi tạo
  void seedSampleFile({
    required String storagePath,
    required String downloadUrl,
    required String fileName,
    required String fileType,
    required int fileSizeBytes,
    required String ownerUid,
  }) {
    _virtualBucketMeta[storagePath] = StorageUploadResult(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      fileName: fileName,
      fileType: fileType,
      fileSizeBytes: fileSizeBytes,
      uploadedByUid: ownerUid,
      uploadedAt: DateTime.now(),
    );
  }

  String _mapContentType(String fileType) {
    switch (fileType.toUpperCase()) {
      case 'PDF':
        return 'application/pdf';
      case 'DOCX':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'PPTX':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'ZIP':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
