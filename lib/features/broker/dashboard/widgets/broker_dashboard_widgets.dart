import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/kpi_card.dart';

class ActItem { final IconData icon; final Color color; final String title, subtitle, time; const ActItem(this.icon, this.color, this.title, this.subtitle, this.time); }

/// KPI card — opaque surface, no BackdropFilter.
/// kpi = [label, value, trendLabel, isPositive, sublabel]
class KCard extends StatelessWidget {
  final List<dynamic> kpi;
  const KCard(this.kpi, {super.key});

  @override
  Widget build(BuildContext context) => BrokerKpiCard(kpi);
}

class Pill extends StatelessWidget {
  final String label; final Color color;
  const Pill(this.label, this.color, {super.key});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyle.bodySmall(color: color).copyWith(fontWeight: FontWeight.w700, fontSize: 11)));
}

class IBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const IBtn(this.icon, {super.key, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 38, height: 38,
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(999), border: Border.all(color: AppTheme.hair(context))),
      child: Icon(icon, size: 18, color: AppTheme.ink(context))));
}

class MonthBar {
  final String label;
  final double value;
  final bool isCurrent;
  const MonthBar({required this.label, required this.value, required this.isCurrent});
}
