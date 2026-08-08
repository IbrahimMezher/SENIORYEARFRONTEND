import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final name   = user['fullName']?.toString() ?? 'U';
    final email  = user['email']?.toString() ?? '';
    final role   = user['role']?['name']?.toString() ?? user['role']?.toString() ?? '';
    final status = user['status']?.toString() ?? 'ACTIVE';
    final color  = AppTheme.statusColor(context, status);
    final bg     = AppTheme.statusBg(context, status);
    return PremiumCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      Monogram(name: name, size: 38, fontSize: 13),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600)),
        Text(email, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(status, style: AppTextStyle.eyebrow(color: color))),
        if (role.isNotEmpty) ...[const SizedBox(height: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: AppTheme.siennaSoft, borderRadius: BorderRadius.circular(999)), child: Text(role.toUpperCase(), style: AppTextStyle.eyebrow(color: AppTheme.sienna)))],
      ]),
    ]));
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  const StatusBadge({super.key, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: AppTheme.statusBg(context, label), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyle.eyebrow(color: AppTheme.statusColor(context, label))));
}
