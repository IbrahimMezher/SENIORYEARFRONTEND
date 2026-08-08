import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';

class ProfileDetailCard extends StatelessWidget {
  final List<ProfileDetailRow> rows;

  const ProfileDetailCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: rows.asMap().entries.map((e) => Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.siennaBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(e.value.icon, size: 16, color: AppTheme.sienna),
              ),
              const SizedBox(width: 12),
              Text(e.value.label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              const Spacer(),
              Flexible(
                child: Text(
                  e.value.value,
                  textAlign: TextAlign.right,
                  style: AppTextStyle.bodyMedium(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          if (e.key < rows.length - 1)
            Divider(height: 1, color: AppTheme.hair(context)),
        ])).toList(),
      ),
    );
  }
}

class ProfileDetailRow {
  final IconData icon;
  final String label, value;
  const ProfileDetailRow(this.icon, this.label, this.value);
}

class ProfileSectionLabel extends StatelessWidget {
  final String label;
  const ProfileSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => SectionTitle(title: label);
}

class ProfileSettingsCard extends StatelessWidget {
  final List<Widget> children;
  const ProfileSettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) => PremiumCard(
    padding: EdgeInsets.zero,
    child: Column(children: children),
  );
}

class ProfileSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProfileSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    leading: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: AppTheme.siennaBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: AppTheme.sienna),
    ),
    title: Text(title, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
    trailing: trailing ??
        Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
    onTap: onTap,
  );
}

class ProfileInnerDivider extends StatelessWidget {
  const ProfileInnerDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 52,
    color: AppTheme.hair(context),
  );
}

class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const ProfileTabBarDelegate({required this.tabBar, required this.color});

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double s, bool o) =>
      Container(color: color, child: tabBar);

  @override
  bool shouldRebuild(ProfileTabBarDelegate old) =>
      old.tabBar != tabBar || old.color != color;
}

class VerifiedBadge extends StatelessWidget {
  final String label;
  final bool verified;
  const VerifiedBadge({super.key, required this.label, required this.verified});

  @override
  Widget build(BuildContext context) {
    final color = verified ? AppTheme.success : AppTheme.warning;
    final bg    = verified ? AppTheme.successBg : AppTheme.warningBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          verified
              ? Icons.verified_outlined
              : Icons.warning_amber_outlined,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${verified ? 'Verified' : 'Unverified'}',
          style: AppTextStyle.eyebrow(color: color).copyWith(fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
