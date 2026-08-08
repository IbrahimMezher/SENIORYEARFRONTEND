import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/features/customer/browse/services/customer_service.dart';
import 'package:fluttertest/features/auth/widgets/widgets.dart';

class DetailRow extends StatelessWidget {
  final String label, value; final bool last;
  const DetailRow(this.label, this.value, {this.last = false});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        Text(value, style: AppTextStyle.mono(size: 12, weight: FontWeight.w600, color: AppTheme.ink(context))),
      ])),
    if (!last) Divider(height: 1, color: AppTheme.hair(context)),
  ]);
}

class CheckRow extends StatelessWidget {
  final String label; final Color color; final bool cross;
  const CheckRow(this.label, this.color, {this.cross = false});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Icon(cross ? Icons.close : Icons.check, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(child: Text(label, style: AppTextStyle.bodySmall(color: AppTheme.ink2(context)))),
    ]));
}

class FieldCard extends StatelessWidget {
  final String label; final TextEditingController controller;
  const FieldCard({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsetsDirectional.only(start: 2, bottom: 6),
          child: Text(label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context)))),
      Container(decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.hair(context))),
        child: TextField(controller: controller, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)),
          decoration: InputDecoration(border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: AppTheme.sienna, width: 1.5))))),
    ]));
}

class ContactBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const ContactBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: AppTheme.siennaSoft, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.sienna.withValues(alpha: 0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 15, color: AppTheme.sienna),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyle.bodySmall(color: AppTheme.sienna).copyWith(fontWeight: FontWeight.w600)),
      ])));
}
