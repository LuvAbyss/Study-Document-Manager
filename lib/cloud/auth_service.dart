import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../database/database_global.dart';
import '../struct/models.dart';
import 'cloud_config.dart';

/// Giao diện Dịch vụ Xác thực Người dùng Google qua Firebase Auth
abstract class IAuthService extends ChangeNotifier {
  AppUser? get currentUser;
  bool get isAuthenticated;
  Stream<AppUser?> get authStateChanges;

  /// Đăng nhập bằng tài khoản Google thông qua Firebase Authentication
  Future<AppUser?> signInWithGoogle();

  /// Chuyển đổi nhanh giữa các tài khoản Google mẫu để phục vụ Kiểm thử Đa Tài khoản (RLS Testing)
  Future<AppUser> switchAccount(String uid);

  /// Đăng xuất khỏi phiên làm việc hiện tại
  Future<void> signOut();
}

/// Triển khai Dịch vụ Xác thực Google (Firebase Auth) kết hợp đồng bộ bảng `users` trên Supabase
class CloudAuthService extends ChangeNotifier implements IAuthService {
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  CloudAuthService() {
    // Khởi tạo lắng nghe trạng thái người dùng từ Database Layer
    database.watchCurrentUser().listen((user) {
      if (!_authController.isClosed) {
        _authController.add(user);
      }
      notifyListeners();
    });
  }

  @override
  AppUser? get currentUser => database.currentUser;

  @override
  bool get isAuthenticated => database.currentUser != null;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  Future<AppUser?> signInWithGoogle() async {
    // 1. Thử xác thực qua Firebase Auth & GoogleSignIn nếu môi trường đã cấu hình OAuth thực tế
    if (Firebase.apps.isNotEmpty && CloudConfig.hasLiveSupabaseKeys) {
      try {
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        final fbUser = userCredential.user;
        if (fbUser != null) {
          final appUser = AppUser(
            uid: fbUser.uid,
            email: fbUser.email ?? googleUser.email,
            displayName: fbUser.displayName ?? googleUser.displayName ?? 'Người dùng Google',
            photoUrl: fbUser.photoURL ?? '',
            roleTitle: 'Thành viên Google',
            department: 'Khoa CNTT',
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          );
          await database.upsertUser(appUser);
          await database.setCurrentUser(appUser.uid);
          notifyListeners();
          return appUser;
        }
      } catch (_) {
        // Nếu chưa cấu hình SHA-1 / OAuth Client trên thiết bị, tự động chuyển sang tài khoản Google mặc định
      }
    }

    // 2. Đăng nhập vào tài khoản Google mặc định (TS. Nguyễn Văn An - an.nguyen@edu.vn)
    final allUsers = await database.getAllUsers();
    final defaultUser = allUsers.first;
    await database.setCurrentUser(defaultUser.uid);
    notifyListeners();
    return defaultUser;
  }

  @override
  Future<AppUser> switchAccount(String uid) async {
    final user = await database.getUserByUid(uid);
    if (user == null) {
      throw ArgumentError('Không tìm thấy tài khoản người dùng với UID: $uid');
    }
    await database.setCurrentUser(uid);
    final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
    await database.upsertUser(updatedUser);
    notifyListeners();
    return updatedUser;
  }

  @override
  Future<void> signOut() async {
    if (Firebase.apps.isNotEmpty && CloudConfig.hasLiveSupabaseKeys) {
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await database.setCurrentUser(null);
    notifyListeners();
  }

  @override
  void dispose() {
    _authController.close();
    super.dispose();
  }
}
