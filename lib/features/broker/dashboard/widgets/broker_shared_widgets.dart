import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class BrokerDivider extends StatelessWidget {
  const BrokerDivider();

  @override
  Widget build(BuildContext context) => Container(
        height: 0.5,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        color: AppTheme.hair(context),
      );
}

class BrokerActivityItem {
  final ActivityType type;
  final String title, subtitle, time, sortKey;
  const BrokerActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.sortKey,
  });
}

enum BadgeType { up, down, neutral }

class KpiCard extends StatelessWidget {
  final String label, value, badge;
  final BadgeType badgeType;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeType,
  });

  Color get _badgeBg {
    switch (badgeType) {
      case BadgeType.up:      return AppTheme.successBg;
      case BadgeType.down:    return AppTheme.dangerBg;
      case BadgeType.neutral: return AppTheme.siennaBg;
    }
  }

  Color get _badgeFg {
    switch (badgeType) {
      case BadgeType.up:      return AppTheme.success;
      case BadgeType.down:    return AppTheme.danger;
      case BadgeType.neutral: return AppTheme.sienna;
    }
  }

  IconData get _badgeIcon {
    switch (badgeType) {
      case BadgeType.up:      return Icons.trending_up_rounded;
      case BadgeType.down:    return Icons.trending_down_rounded;
      case BadgeType.neutral: return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: AppTheme.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyle.mono(
              size: 22,
              weight: FontWeight.w800,
              color: AppTheme.ink(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_badgeIcon, size: 11, color: _badgeFg),
              const SizedBox(width: 4),
              Text(badge,
                  style: AppTextStyle.eyebrow(color: _badgeFg)
                      .copyWith(fontSize: 10)),
            ]),
          ),
        ],
      ),
    );
  }
}

enum Status { active, pending, review }

class Client {
  final String initials, name, policy, value;
  final Status status;
  const Client(this.initials, this.name, this.policy, this.value, this.status);
}

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  String get _statusLabel {
    switch (client.status) {
      case Status.active:  return 'Active';
      case Status.pending: return 'Pending';
      case Status.review:  return 'In review';
    }
  }

  Color get _statusBg {
    switch (client.status) {
      case Status.active:  return AppTheme.successBg;
      case Status.pending: return AppTheme.siennaBg;
      case Status.review:  return AppTheme.warningBg;
    }
  }

  Color get _statusFg {
    switch (client.status) {
      case Status.active:  return AppTheme.success;
      case Status.pending: return AppTheme.sienna;
      case Status.review:  return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Monogram(name: client.name, size: 40, fontSize: 14),
        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(client.name,
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(client.policy,
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            ],
          ),
        ),

        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(client.value,
              style: AppTextStyle.mono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: AppTheme.ink(context))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_statusLabel,
                style: AppTextStyle.eyebrow(color: _statusFg)
                    .copyWith(fontSize: 10)),
          ),
        ]),
      ]),
    );
  }
}

enum ActivityType { success, client, warning, document }

class Activity {
  final ActivityType type;
  final String title, subtitle, time;
  const Activity(this.type, this.title, this.subtitle, this.time);
}

class ActivityRow extends StatelessWidget {
  final Activity activity;

  const ActivityRow({super.key, required this.activity});

  _IconTheme get _theme {
    switch (activity.type) {
      case ActivityType.success:
        return _IconTheme(Icons.check_rounded, AppTheme.success, AppTheme.successBg);
      case ActivityType.client:
        return _IconTheme(Icons.person_rounded, AppTheme.sienna, AppTheme.siennaBg);
      case ActivityType.warning:
        return _IconTheme(Icons.access_time_rounded, AppTheme.warning, AppTheme.warningBg);
      case ActivityType.document:
        return _IconTheme(Icons.description_rounded, AppTheme.sienna, AppTheme.siennaBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _theme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: t.bg,
          ),
          child: Icon(t.icon, size: 16, color: t.fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(activity.title,
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(activity.subtitle,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ]),
        ),
        Text(activity.time,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
      ]),
    );
  }
}

class _IconTheme {
  final IconData icon;
  final Color fg, bg;
  const _IconTheme(this.icon, this.fg, this.bg);
}
