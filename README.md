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

## Công nghệ sử dụng

- [Flutter](https://flutter.dev/)
- Dart
- Provider
- Material Design
- UUID
- Intl

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
├── database/   # Cơ sở dữ liệu và dữ liệu mẫu
├── pages/      # Các màn hình ứng dụng
├── struct/     # Model và service xử lý nghiệp vụ
├── widgets/    # Widget dùng chung
└── main.dart   # Điểm khởi chạy ứng dụng
```

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
