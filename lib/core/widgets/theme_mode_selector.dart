import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (ctrl) {
        final mode = ctrl.themeMode;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppTheme.bg(context),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.hair(context)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _seg(context, ctrl, 'light'.tr, ThemeMode.light, mode),
            _seg(context, ctrl, 'dark'.tr, ThemeMode.dark, mode),
            _seg(context, ctrl, 'auto'.tr, ThemeMode.system, mode),
          ]),
        );
      },
    );
  }

  Widget _seg(BuildContext context, ThemeController ctrl, String label,
      ThemeMode value, ThemeMode current) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => ctrl.setMode(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: AppTextStyle.bodySmall(
            color: selected ? AppTheme.ink(context) : AppTheme.muted(context),
          ).copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
