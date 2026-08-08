import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  static const _key = "themeMode";

  ThemeMode get themeMode {
    switch (_box.read(_key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  ThemeMode get theme => themeMode;

  bool get isDarkMode {
    final m = themeMode;
    if (m == ThemeMode.system) {
      return Get.isPlatformDarkMode;
    }
    return m == ThemeMode.dark;
  }

  void setMode(ThemeMode mode) {
    final value = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    _box.write(_key, value);
    Get.changeThemeMode(mode);
    update();
  }

  void toggleTheme() {
    setMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }
}
