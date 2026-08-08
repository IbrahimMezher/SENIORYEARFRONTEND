import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.toString();

    if (msg.contains('ViewInsets cannot be negative') ||
        msg.contains('_viewInsets.isNonNegative') ||
        msg.contains('size.isFinite') && msg.contains('Stack')) {
      return;
    }
    FlutterError.presentError(details);
  };

  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    final msg = error.toString();
    if (msg.contains('ViewInsets cannot be negative') ||
        msg.contains('_viewInsets.isNonNegative')) {
      return true;
    }
    return false;
  };

  await dotenv.load(fileName: '.env');
  await GetStorage.init();
  Get.put(ThemeController());
  Get.put(LanguageController());
  runApp(const MyApp());
}
