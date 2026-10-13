import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Cấu hình kết nối Hệ sinh thái Cloud (Firebase Auth + Firebase Storage + Supabase Postgres)
class CloudConfig {
  /// URL dự án Supabase (có thể truyền qua --dart-define=SUPABASE_URL=...)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cashew-studydocs.supabase.co',
  );

  /// Anon Key của Supabase (có thể truyền qua --dart-define=SUPABASE_ANON_KEY=...)
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.cashew-studydocs-anon-key',
  );

  /// Tên Bucket lưu trữ tệp vật lý trên Firebase Storage
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'gs://cashew-studydocs.firebasestorage.app',
  );

  /// Kiểm tra xem thông tin khóa thực tế đã được truyền qua môi trường hay đang chạy ở chế độ Cloud Sandbox
  static bool get hasLiveSupabaseKeys =>
      const String.fromEnvironment('SUPABASE_URL').isNotEmpty &&
      const String.fromEnvironment('SUPABASE_ANON_KEY').isNotEmpty;

  /// Tạo cấu trúc FirebaseOptions tiêu chuẩn cho ứng dụng Flutter
  static FirebaseOptions get currentPlatformOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyCashewStudyDocsWebKey'),
        appId: '1:882910394812:web:cashewstudydocs01',
        messagingSenderId: '882910394812',
        projectId: 'cashew-studydocs',
        authDomain: 'cashew-studydocs.firebaseapp.com',
        storageBucket: 'cashew-studydocs.firebasestorage.app',
      );
    }
    return const FirebaseOptions(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY', defaultValue: 'AIzaSyCashewStudyDocsMobileKey'),
      appId: '1:882910394812:android:cashewstudydocs01',
      messagingSenderId: '882910394812',
      projectId: 'cashew-studydocs',
      storageBucket: 'cashew-studydocs.firebasestorage.app',
    );
  }
}
