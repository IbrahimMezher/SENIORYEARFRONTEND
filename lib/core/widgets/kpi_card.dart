import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';

class KpiItem {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bg;
  /// Optional trend text, e.g. "+12.4%"
  final String? trend;
  final bool? trendPositive;

  const KpiItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    this.trend,
    this.trendPositive,
  });
}

/// Row of 2–4 KPI cards — opaque surfaces, no blur, no glass.
///
/// Each cell: icon top-left, large mono value, label, optional trend badge.
class KpiCard extends StatelessWidget {
  final List<KpiItem> items;
  const KpiCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _KpiCell(item: e.value)),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 56,
                    color: AppTheme.hair(context),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final KpiItem item;
  const _KpiCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final trend = item.trend;
    final positive = item.trendPositive ?? true;
    final trendColor = positive
        ? (dark ? AppTheme.darkSuccess : AppTheme.success)
        : (dark ? AppTheme.darkDanger  : AppTheme.danger);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context, r: AppTheme.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(item.icon, size: 18, color: item.color),
          ),
          const SizedBox(height: 10),
          // Value
          Text(
            item.value,
            style: AppTextStyle.mono(
              size: 22,
              weight: FontWeight.w700,
              color: AppTheme.ink(context),
            ),
          ),
          const SizedBox(height: 2),
          // Label
          Text(
            item.label,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Trend badge
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 11,
                  color: trendColor,
                ),
                const SizedBox(width: 2),
                Text(
                  trend,
                  style: AppTextStyle.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Broker-style large KPI card with backdrop (replicates KCard from broker_dashboard_widgets).
/// Now uses opaque surface — no BackdropFilter.
class BrokerKpiCard extends StatelessWidget {
  /// [label, value, trendLabel, isPositive, sublabel]
  final List<dynamic> kpi;
  const BrokerKpiCard(this.kpi, {super.key});

  @override
  Widget build(BuildContext context) {
    final dark     = AppTheme.isDark(context);
    final positive = kpi[3] as bool;
    final trendColor = positive
        ? (dark ? AppTheme.darkSuccess : AppTheme.success)
        : (dark ? AppTheme.darkDanger  : AppTheme.danger);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration(context, r: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(kpi[0] as String,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 8),
        Text(kpi[1] as String,
            style: AppTextStyle.mono(
                size: 28,
                weight: FontWeight.w700,
                color: AppTheme.ink(context))),
        const SizedBox(height: 4),
        Row(children: [
          Icon(
            positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: trendColor,
          ),
          const SizedBox(width: 3),
          Text(kpi[2] as String,
              style: AppTextStyle.mono(
                  size: 10, weight: FontWeight.w600, color: trendColor)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(kpi[4] as String,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ),
        ]),
      ]),
    );
  }
}
