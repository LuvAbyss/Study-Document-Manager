# Study Document Manager

Ứng dụng Flutter giúp sinh viên, giảng viên và người tự học quản lý tài liệu học tập tập trung, dễ tìm kiếm và theo dõi tiến độ.

## Giới thiệu

Study Document Manager hỗ trợ quản lý các loại tài liệu:

- Bài giảng, slide và ghi chú
- Bài tập, đồ án và hạn nộp
- Sách, tài liệu tham khảo và liên kết bên ngoài
- Đề cương ôn tập, ngân hàng câu hỏi và đề thi mẫu

### Tính năng chính

- Thêm, sửa, xóa và xem chi tiết tài liệu
- Phân loại tài liệu theo môn học, loại, trạng thái và mức độ ưu tiên
- Ghim tài liệu quan trọng và đánh dấu yêu thích
- Tìm kiếm theo tiêu đề, mô tả, môn học và tags
- Lọc và sắp xếp theo nhiều tiêu chí
- Theo dõi trạng thái bài tập: chưa làm, đang làm và đã hoàn thành
- Dashboard thống kê số lượng tài liệu, nhiệm vụ cần làm và cảnh báo quá hạn
- Lưu trữ dữ liệu cục bộ, phù hợp sử dụng offline
- Đăng nhập và chuyển đổi tài khoản Google qua Firebase Authentication
- Đồng bộ hồ sơ người dùng, môn học, tài liệu và quyền chia sẻ với Supabase
- Tải lên, tải xuống và quản lý tệp đính kèm trên Firebase Storage
- Chia sẻ tài liệu theo email với hai vai trò `viewer` và `editor`
- Lọc tài liệu theo phạm vi: tất cả, tài liệu của tôi hoặc được chia sẻ với tôi
- Tìm kiếm theo tiêu đề, mô tả, môn học, tags, chủ sở hữu và đường dẫn tệp
- Áp dụng Row Level Security (RLS) để cô lập dữ liệu giữa các tài khoản
- Kiểm soát quyền chi tiết: chủ sở hữu có toàn quyền, editor được cập nhật,
  viewer chỉ được xem và tải tệp

### Kiến trúc Cloud

Ứng dụng hỗ trợ mô hình local-first và có thể kết nối các dịch vụ cloud:

- **Firebase Authentication:** xác thực Google và quản lý phiên đăng nhập
- **Firebase Storage:** lưu tệp theo cấu trúc
  `users/{ownerUid}/subjects/{subjectId}/documents/{documentId}/{fileName}`
- **Supabase PostgreSQL:** đồng bộ users, subjects, documents và permissions
- **Supabase RLS:** thực thi quyền truy cập ở tầng dữ liệu, bên cạnh kiểm tra
  quyền trong ứng dụng

Khi chạy local hoặc test, ứng dụng sử dụng dữ liệu mẫu và cloud sandbox. Có thể
truyền thông tin kết nối thật bằng `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=FIREBASE_API_KEY=your-firebase-api-key \
  --dart-define=FIREBASE_STORAGE_BUCKET=gs://your-project.firebasestorage.app
```

## Công nghệ sử dụng

- [Flutter](https://flutter.dev/)
- Dart
- Provider
- Material Design
- UUID
- Intl
- Firebase Authentication
- Firebase Storage
- [Supabase](https://supabase.com/) và PostgreSQL RLS

## Yêu cầu hệ thống

Trước khi cài đặt, hãy chuẩn bị:

- Flutter SDK tương thích với Dart SDK `^3.13.3`
- Android Studio và Android SDK nếu chạy trên Android
- Xcode nếu chạy trên macOS/iOS
- Git

Kiểm tra môi trường Flutter:

```bash
flutter doctor
```

## Cài đặt và chạy ứng dụng

### 1. Tải mã nguồn

```bash
git clone https://github.com/LuvAbyss/Study-Document-Manager.git
cd Study-Document-Manager
```

### 2. Cài đặt dependencies

```bash
flutter pub get
```

### 3. Kiểm tra thiết bị chạy

```bash
flutter devices
```

Khởi động trình giả lập Android hoặc kết nối thiết bị thật nếu danh sách chưa có thiết bị phù hợp.

### 4. Chạy ứng dụng

```bash
flutter run
```

Có thể chỉ định thiết bị cụ thể:

```bash
flutter run -d chrome       # Chạy trên trình duyệt Chrome
flutter run -d windows      # Chạy trên Windows
flutter run -d <device_id> # Chạy trên thiết bị cụ thể
```

## Build bản phát hành

### Android APK

```bash
flutter build apk --release
```

File APK được tạo tại:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Web

```bash
flutter build web --release
```

### Windows

```bash
flutter build windows --release
```

## Kiểm thử và phân tích mã nguồn

Chạy toàn bộ test:

```bash
flutter test
```

Phân tích mã nguồn:

```bash
flutter analyze
```

## Cấu trúc thư mục chính

```text
lib/
├── cloud/       # Firebase Auth/Storage, Supabase sync và policy engine
├── database/   # Cơ sở dữ liệu và dữ liệu mẫu
├── pages/       # Các màn hình ứng dụng
├── struct/      # Model và service xử lý nghiệp vụ
├── widgets/     # Widget dùng chung
└── main.dart    # Điểm khởi chạy ứng dụng

supabase/
└── migrations/  # Schema PostgreSQL và chính sách RLS

firebase/
└── storage.rules # Quy tắc truy cập Firebase Storage
```

## Kiểm thử cloud và phân quyền

Test suite bao gồm các luồng local database, giao diện và cloud/RLS:

- Xác thực và chuyển đổi giữa nhiều tài khoản
- Đồng bộ hồ sơ người dùng và tài liệu
- Kiểm tra đường dẫn Firebase Storage
- Kiểm tra quyền `owner`, `editor`, `viewer` và tài khoản ngoài phạm vi chia sẻ
- Kiểm tra tìm kiếm, lọc và các thao tác CRUD trên tài liệu

Migration Supabase nằm tại
[`supabase/migrations/001_supabase_schema_and_rls.sql`](supabase/migrations/001_supabase_schema_and_rls.sql);
quy tắc Firebase Storage nằm tại
[`firebase/storage.rules`](firebase/storage.rules).

## Đóng góp

1. Tạo fork của repository.
2. Tạo branch cho thay đổi mới:

   ```bash
   git checkout -b feature/ten-tinh-nang
   ```

3. Thực hiện thay đổi và chạy `flutter analyze` cùng `flutter test`.
4. Tạo pull request với mô tả rõ ràng về thay đổi.

## Giấy phép

Dự án hiện chưa công bố giấy phép sử dụng riêng.
