import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/settings_sheets.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/features/customer/checkout/services/checkout_service.dart';

class SettingsTile extends StatelessWidget {

final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const SettingsTile(this.icon, this.label, {this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.accentSoft(context), borderRadius: BorderRadius.circular(28)), child: Icon(icon, size: 16, color: AppTheme.sienna)),
    title: Text(label, style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
    trailing: trailing ?? Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.muted(context)),
    onTap: onTap,
  );
}

class MethodTile extends StatelessWidget {
  final IconData icon; final String label; final bool selected; final VoidCallback onTap;
  const MethodTile({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? AppTheme.siennaSoft : AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: selected ? AppTheme.sienna : AppTheme.hair(context), width: selected ? 1.5 : 1),
      ),
      child: Row(children: [
        Icon(icon, color: selected ? AppTheme.sienna : AppTheme.muted(context), size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyle.bodySmall(color: selected ? AppTheme.sienna : AppTheme.ink(context)).copyWith(fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
        if (selected) const Icon(Icons.check_circle, color: AppTheme.sienna, size: 18),
      ]),
    ),
  );
}

class FI extends StatelessWidget {
  final TextEditingController ctrl; final String label; final TextInputType? keyboard;
  const FI(this.ctrl, this.label, {this.keyboard});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsetsDirectional.only(start: 2, bottom: 5), child: Text(label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context)))),
      Container(decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.hair(context))),
        child: TextField(controller: ctrl, keyboardType: keyboard, style: AppTextStyle.bodySmall(color: AppTheme.ink(context)),
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
    ]));
}

class TabDel extends SliverPersistentHeaderDelegate {
  final TabBar tabBar; final Color color;
  const TabDel({required this.tabBar, required this.color});
  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override Widget build(_, double s, bool __) => Container(color: color, child: tabBar);
  @override bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
