import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cloud/auth_service.dart';
import 'cloud/cloud_config.dart';
import 'cloud/supabase_sync_service.dart';
import 'colors.dart';
import 'database/app_database.dart';
import 'database/database_global.dart';
import 'pages/home_page.dart';
import 'struct/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase Core (Hỗ trợ Google Auth & Firebase Storage)
  try {
    await Firebase.initializeApp(
      options: CloudConfig.currentPlatformOptions,
    );
  } catch (_) {
    // Hoạt động an toàn trong chế độ Cloud Sandbox nếu chưa nạp tệp cấu hình nền tảng
  }

  // 2. Khởi tạo Supabase Client nếu đã cấu hình URL/AnonKey thực tế
  await SupabaseSyncService.instance.initializeIfConfigured();

  // 3. Khởi tạo tầng cơ sở dữ liệu (Database Layer + RLS Engine) theo nguyên lý Cashew
  database = AppDatabase(populateSampleData: true, enforceRls: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider<IAuthService>(create: (_) => CloudAuthService()),
      ],
      child: const StudyDocumentApp(),
    ),
  );
}

/// Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew & Hệ sinh thái Cloud
class StudyDocumentApp extends StatelessWidget {
  const StudyDocumentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);

    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập',
      debugShowCheckedModeBanner: false,
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: settings.themeMode,
      home: const HomePage(),
    );
  }
}
