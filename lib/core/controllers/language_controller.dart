import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  final _box = GetStorage();
  static const _key = 'language';

  String get languageCode => _box.read(_key) ?? 'en';
  Locale get locale => Locale(languageCode);
  bool get isArabic => languageCode == 'ar';
  String get displayName => isArabic ? 'العربية' : 'English';

  void setLanguage(String code) {
    _box.write(_key, code);
    Get.updateLocale(Locale(code));
    update();
  }
}
