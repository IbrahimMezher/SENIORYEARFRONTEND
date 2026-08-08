import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/customer/browse/services/customer_service.dart';

class TimelineStep {
  final String label, sublabel;
  final bool done, active, failed;
  final IconData icon;
  const TimelineStep({required this.label, required this.sublabel, this.done = false, this.active = false, this.failed = false, required this.icon});
}

class DetailRow extends StatelessWidget {
  final String label, value; final bool last;
  const DetailRow(this.label, this.value, {this.last = false});
  @override Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11), child: Row(children: [
      Text(label, style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: AppTextStyle.mono(size: 12, weight: FontWeight.w600, color: AppTheme.ink(context)))),
    ])),
    if (!last) Divider(height: 1, color: AppTheme.hair(context)),
  ]);
}
