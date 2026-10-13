import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_document_manager/database/app_database.dart';
import 'package:study_document_manager/database/database_global.dart';
import 'package:study_document_manager/struct/settings.dart';
import 'package:study_document_manager/colors.dart';
import 'package:study_document_manager/pages/home_page.dart';
import 'package:study_document_manager/pages/add_edit_document_page.dart';
import 'package:study_document_manager/widgets/document_card.dart';

void main() {
  setUp(() {
    // Khởi tạo Database với dữ liệu mẫu trước mỗi test widget
    database = AppDatabase(populateSampleData: true);
  });

  tearDown(() {
    database.dispose();
  });

  testWidgets('Kiểm thử giao diện ứng dụng Cashew StudyDocs: Hiển thị Dashboard và điều hướng Tabs', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
        ],
        child: MaterialApp(
          theme: AppColors.lightTheme,
          home: const HomePage(),
        ),
      ),
    );

    // Chờ reactive streams và animations hoàn tất
    await tester.pumpAndSettle();

    // 1. Kiểm tra tiêu đề chính hiển thị
    expect(find.text('Cashew StudyDocs'), findsOneWidget);
    expect(find.text('Học kỳ 1 • 2026-2027'), findsOneWidget);

    // 2. Kiểm tra các thẻ KPI trên Dashboard
    expect(find.text('Tổng tài liệu'), findsOneWidget);
    expect(find.text('Bài tập cần nộp'), findsOneWidget);
    expect(find.text('Khẩn cấp'), findsWidgets);
    expect(find.text('Tiến độ học tập tổng thể'), findsOneWidget);

    // 3. Kiểm tra thanh điều hướng dưới đáy (NavigationBar)
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Tài liệu'), findsOneWidget);
    expect(find.text('Môn học'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);

    // 4. Chuyển sang Tab "Tài liệu"
    await tester.tap(find.text('Tài liệu'));
    await tester.pumpAndSettle();

    // Xác nhận đã chuyển sang trang Kho tài liệu học tập
    expect(find.text('Kho tài liệu học tập'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search bar

    // 5. Chuyển sang Tab "Môn học"
    await tester.tap(find.text('Môn học'));
    await tester.pumpAndSettle();

    // Xác nhận đã chuyển sang trang Quản lý Môn học
    expect(find.text('Quản lý Môn học'), findsOneWidget);
    expect(find.textContaining('Kiến trúc Phần mềm'), findsOneWidget);

    // 6. Chuyển sang Tab "Tìm kiếm"
    await tester.tap(find.text('Tìm kiếm'));
    await tester.pumpAndSettle();

    expect(find.text('Tìm kiếm tài liệu'), findsOneWidget);
  });

  testWidgets('Kiểm thử tạo tài liệu mới qua AddEditDocumentPage', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
        ],
        child: MaterialApp(
          theme: AppColors.lightTheme,
          home: const AddEditDocumentPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Nhập tiêu đề
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, 'Slide Kiến trúc Phần mềm Nâng cao');

    // Nhấn nút Lưu (biểu tượng Check trên AppBar)
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pumpAndSettle();

    // Kiểm tra tài liệu đã được lưu vào database
    final docs = await database.getAllDocuments();
    final created = docs.where((d) => d.title == 'Slide Kiến trúc Phần mềm Nâng cao');
    expect(created.isNotEmpty, true);
  });

  testWidgets('Kiểm thử tìm kiếm trên màn hình Kho tài liệu', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
        ],
        child: MaterialApp(
          theme: AppColors.lightTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Chuyển sang Tab Tài liệu
    await tester.tap(find.text('Tài liệu'));
    await tester.pumpAndSettle();

    // Thử tìm 'Chương 3'
    await tester.enterText(find.byType(TextField), 'Chương 3');
    await tester.pumpAndSettle();

    // Xác nhận kết quả tìm thấy đúng 1 thẻ DocumentCard tương ứng
    expect(find.byType(DocumentCard), findsOneWidget);
  });

  testWidgets('Kiểm thử Tab Cloud & RLS: Chuyển đổi giữa 3+ tài khoản Google và cập nhật quyền truy cập', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppSettings()),
        ],
        child: MaterialApp(
          theme: AppColors.lightTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Chuyển sang Tab "Cloud & RLS"
    await tester.tap(find.text('Cloud & RLS'));
    await tester.pumpAndSettle();

    expect(find.text('Cloud Auth & Phân quyền RLS'), findsOneWidget);
    expect(find.text('TS. Nguyễn Văn An'), findsWidgets);

    // Chuyển sang tài khoản thứ 2 (ThS. Trần Thị Bình - uid_user_2)
    await tester.tap(find.byKey(const Key('switch_account_uid_user_2')));
    await tester.pumpAndSettle();

    expect(database.currentUserUid, 'uid_user_2');
    // Tài khoản 2 chỉ được xem 5/7 tài liệu theo RLS
    expect((await database.getAllDocuments()).length, 5);

    // Chuyển sang tài khoản thứ 3 (Lê Hoàng Cường - uid_user_3)
    await tester.drag(find.byType(ListView).last, const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('switch_account_uid_user_3')));
    await tester.pumpAndSettle();

    expect(database.currentUserUid, 'uid_user_3');
    expect((await database.getAllDocuments()).length, 5);
  });
}
