import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database/app_database.dart';
import 'database/database_global.dart';
import 'struct/settings.dart';
import 'colors.dart';
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo tầng cơ sở dữ liệu (Database Layer) theo nguyên lý Cashew
  database = AppDatabase(populateSampleData: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
      ],
      child: const StudyDocumentApp(),
    ),
  );
}

/// Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew
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
