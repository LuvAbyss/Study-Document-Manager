import 'package:flutter/material.dart';
import 'models.dart';

/// Quản lý cấu hình và tùy chọn người dùng (Application Preferences / Settings)
class AppSettings extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  DocumentSortOption _defaultSortOption = DocumentSortOption.createdDesc;
  bool _compactView = false;
  bool _enableNotifications = true;

  ThemeMode get themeMode => _themeMode;
  DocumentSortOption get defaultSortOption => _defaultSortOption;
  bool get compactView => _compactView;
  bool get enableNotifications => _enableNotifications;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setDefaultSortOption(DocumentSortOption option) {
    _defaultSortOption = option;
    notifyListeners();
  }

  void toggleCompactView() {
    _compactView = !_compactView;
    notifyListeners();
  }

  void setEnableNotifications(bool enable) {
    _enableNotifications = enable;
    notifyListeners();
  }
}
