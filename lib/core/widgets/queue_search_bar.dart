import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class QueueSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String? trailingLabel;

  const QueueSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.onClear,
    this.trailingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.trim().isNotEmpty;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hairStrong(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.isDark(context)
                ? const Color(0x33000000)
                : const Color(0x0D172033),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.search_rounded, size: 19, color: AppTheme.sienna),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                .copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: hint,
              hintStyle: AppTextStyle.bodySmall(
                color: AppTheme.muted(context),
              ),
            ),
          ),
        ),
        if (trailingLabel != null && !hasText) ...[
          Container(
            margin: const EdgeInsetsDirectional.only(end: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentSoft(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailingLabel!,
              style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                  .copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
        if (hasText)
          IconButton(
            tooltip: 'Clear',
            onPressed: onClear ?? () => onChanged(''),
            icon: Icon(Icons.close_rounded,
                size: 18, color: AppTheme.muted(context)),
          ),
      ]),
    );
  }
}
