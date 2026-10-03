import 'package:intl/intl.dart';

/// Các hàm tiện ích định dạng dữ liệu cho UI và Business Logic
class DocumentFormatters {
  static final DateFormat _fullDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _displayDateFormat = DateFormat('dd MMM, yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('HH:mm dd/MM/yyyy');

  /// Định dạng ngày hiển thị thân thiện (Hôm nay, Ngày mai, Quá hạn,...)
  static String formatDueDate(DateTime? date) {
    if (date == null) return 'Không có hạn';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference < 0) {
      final daysAgo = -difference;
      return 'Quá hạn $daysAgo ngày';
    } else if (difference == 0) {
      return 'Hôm nay (${DateFormat('HH:mm').format(date)})';
    } else if (difference == 1) {
      return 'Ngày mai (${DateFormat('HH:mm').format(date)})';
    } else if (difference < 7) {
      return 'Còn $difference ngày (${_fullDateFormat.format(date)})';
    } else {
      return _displayDateFormat.format(date);
    }
  }

  /// Định dạng ngày tháng cơ bản
  static String formatDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  /// Định dạng ngày giờ chi tiết
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// Định dạng dung lượng tệp tin (bytes -> KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${suffixes[i]}';
  }

  /// Rút gọn văn bản với độ dài tối đa
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
