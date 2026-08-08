import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/customer/cart/services/cart_service.dart';
import 'package:fluttertest/features/customer/checkout/pages/checkout_page.dart';

class SummaryRow extends StatelessWidget {

final String label, value;
  final Color? valueColor;
  const SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          Text(
            value,
            style: AppTextStyle.mono(
              size: 13,
              weight: FontWeight.w600,
              color: valueColor ?? AppTheme.ink(context),
            ),
          ),
        ]),
      );
}
