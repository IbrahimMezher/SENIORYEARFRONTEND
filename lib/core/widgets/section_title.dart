import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(
      {super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          // Gradient accent bar
          Container(
            width: 3,
            height: 15,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradientVertical,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ]),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
