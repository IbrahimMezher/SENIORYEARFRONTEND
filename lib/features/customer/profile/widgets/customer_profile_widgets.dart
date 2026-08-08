import 'package:fluttertest/features/customer/profile/services/customer_profile_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/utils/settings_sheets.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';

class CustomerProfileTab extends StatelessWidget {
  final String fullName, email, phone, role;
  final List<dynamic> addresses;
  final bool addrsLoading;
  final VoidCallback onAddAddress;
  final void Function(int) onDeleteAddress;
  final bool isDark;
  final Color primary;

  const CustomerProfileTab({
    super.key,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.addresses,
    required this.addrsLoading,
    required this.onAddAddress,
    required this.onDeleteAddress,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          SectionTitle(title: 'personal_info'.tr),
          const SizedBox(height: 10),
          CustomerDetailCard(rows: [
            CustomerDetailRow(Icons.person_outline, 'Full Name', fullName),
            CustomerDetailRow(Icons.mail_outline, 'Email', email),
            if (phone.isNotEmpty)
              CustomerDetailRow(Icons.phone_outlined, 'Phone', phone),
            CustomerDetailRow(Icons.badge_outlined, 'Role', role.toUpperCase()),
          ]),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            SectionTitle(title: 'saved_addresses'.tr),
            GestureDetector(
              onTap: onAddAddress,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                    color: AppTheme.siennaBg,
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, size: 14, color: AppTheme.sienna),
                  SizedBox(width: 4),
                  Text('add'.tr,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.sienna)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          if (addrsLoading)
            const Center(
                child: CircularProgressIndicator(color: AppTheme.sienna))
          else if (addresses.isEmpty)
            PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.location_off_outlined,
                      size: 36,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text('no_addresses'.tr,
                      style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35))),
                  const SizedBox(height: 12),
                  GestureDetector(
                      onTap: onAddAddress,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppTheme.siennaBg,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('add_first_address'.tr,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.sienna)),
                      )),
                ]))
          else
            ...addresses.map((addr) {
              final id = addr['addressId'] is int
                  ? addr['addressId'] as int
                  : int.tryParse(addr['addressId'].toString()) ?? 0;
              final isDefault = addr['isDefault'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDefault
                        ? AppTheme.sienna.withValues(alpha: 0.4)
                        : AppTheme.hair(context),
                    width: isDefault ? 1.5 : 1,
                  ),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isDefault
                                  ? AppTheme.siennaBg
                                  : AppTheme.bg(context)),
                          child: Icon(Icons.location_on_outlined,
                              color: isDefault
                                  ? AppTheme.sienna
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.38),
                              size: 17)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            if (addr['fullName'] != null)
                              Text(addr['fullName'].toString(),
                                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                                      .copyWith(fontWeight: FontWeight.w600)),
                            Text(
                                '${addr['street'] ?? ''}, ${addr['city'] ?? ''}${addr['state'] != null && addr['state'].toString().isNotEmpty ? ', ${addr['state']}' : ''}, ${addr['country'] ?? ''}',
                                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                            if (addr['phoneNumber'] != null)
                              Text(addr['phoneNumber'].toString(),
                                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                            if (isDefault)
                              Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: AppTheme.siennaBg,
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      child: Text('default'.tr,
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.sienna)))),
                          ])),
                      GestureDetector(
                          onTap: () => onDeleteAddress(id),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: AppTheme.dangerBg,
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.delete_outline,
                                size: 15, color: AppTheme.danger),
                          )),
                    ]),
              );
            }),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/logout'),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.logout),
              label: Text('log_out'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
  }
}

class CustomerSettingsTab extends StatelessWidget {
  final bool isDark;
  final Color primary;
  const CustomerSettingsTab(
      {super.key, required this.isDark, required this.primary});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          SectionTitle(title: 'appearance'.tr),
          const SizedBox(height: 10),
          CustomerCard(children: [
            GetBuilder<ThemeController>(
                builder: (ctrl) => SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      title: Text('dark_mode'.tr, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
                      subtitle: Text(ctrl.isDarkMode ? 'on'.tr : 'off'.tr,
                          style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                      secondary: Icon(
                          ctrl.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.sienna),
                      value: ctrl.isDarkMode,
                      onChanged: (_) => ctrl.toggleTheme(),
                      activeThumbColor: AppTheme.sienna,
                      activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
                    )),
          ]),
          const SizedBox(height: 24),
          SectionTitle(title: 'account'.tr),
          const SizedBox(height: 10),
          CustomerCard(children: [
            CustomerTile(
                icon: Icons.lock_outline,
                title: 'change_password'.tr,
                onTap: () => showChangePasswordSheet(context)),
            const CustomerDivider(),
            CustomerTile(
                icon: Icons.notifications_outlined,
                title: 'notifications'.tr,
                onTap: () => showNotificationsSheet(context)),
            const CustomerDivider(),
            GetBuilder<LanguageController>(
                builder: (langCtrl) => CustomerTile(
                      icon: Icons.language_outlined,
                      title: 'language'.tr,
                      trailing:
                          Text(langCtrl.displayName, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                      onTap: () => showLanguageSheet(context),
                    )),
          ]),
        ]);
  }
}

class CustomerPrivacyTab extends StatefulWidget {
  final bool isDark;
  final Color primary;
  const CustomerPrivacyTab(
      {super.key, required this.isDark, required this.primary});

  @override
  State<CustomerPrivacyTab> createState() => _CustomerPrivacyTabState();
}

class _CustomerPrivacyTabState extends State<CustomerPrivacyTab> {
  final _authService = CustomerProfileService();
  bool _twoFaEnabled = false;
  String _twoFaMethod = '';
  bool _profileVisible = true;
  bool _contactVisible = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final privacy = await _authService.getPrivacy();
      final twoFaEnabled = await SecureStorageService.isTwoFaEnabled();
      final twoFaMethod = await SecureStorageService.getTwoFaMethod();
      if (mounted) {
        setState(() {
          _twoFaEnabled = twoFaEnabled ?? false;
          _twoFaMethod = twoFaMethod ?? '';
          _profileVisible = privacy['profileVisible'] == true;
          _contactVisible = privacy['contactVisible'] == true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle2FA() async {
    if (_twoFaEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('disable_2fa'.tr),
          content: Text('disable_2fa_confirm'.tr),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr)),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
                child: Text('disable'.tr)),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        await _authService.disable2FA();
        await SecureStorageService.write('twoFaEnabled', 'false');
        await SecureStorageService.write('twoFaMethod', '');
        if (mounted) {
          setState(() {
            _twoFaEnabled = false;
            _twoFaMethod = '';
          });
        }
        _snack('2FA disabled.');
      } catch (e) {
        _snack(e.toString().replaceFirst('Exception: ', ''));
      }
    } else {
      _show2FASetup();
    }
  }

  void _show2FASetup() {
    String selected = 'email';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: Text('enable_2fa'.tr),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('choose_2fa_receive'.tr),
                  const SizedBox(height: 16),
                  MethodTile(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      selected: selected == 'email',
                      onTap: () => setS(() => selected = 'email')),
                  const SizedBox(height: 8),
                  MethodTile(
                    icon: Icons.sms_outlined,
                    label: 'SMS (requires verified phone)',
                    selected: selected == 'sms',
                    onTap: () async {
                      final phoneVerified =
                          await SecureStorageService.isPhoneVerified() ?? false;
                      if (!phoneVerified) {
                        Navigator.pop(ctx);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('verify_phone_first'.tr),
                            backgroundColor: AppTheme.sienna,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ));
                          await Future.delayed(const Duration(seconds: 1));
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/verify-phone');
                          }
                        }
                      } else {
                        setS(() => selected = 'sms');
                      }
                    },
                  ),
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('cancel'.tr)),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await _authService.setup2FA(selected);
                        if (mounted)
                          setState(() {
                            _twoFaEnabled = true;
                            _twoFaMethod = selected;
                          });
                        _snack('2FA enabled via $selected!');
                      } catch (e) {
                        _snack(e.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                    child: Text('enable'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              )),
    );
  }

  Future<void> _updatePrivacy() async {
    try {
      await _authService.updatePrivacy(
          profileVisible: _profileVisible, contactVisible: _contactVisible);
    } catch (_) {}
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.sienna));

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          SectionTitle(title: 'data_privacy'.tr),
          const SizedBox(height: 10),
          CustomerCard(children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AppTheme.siennaBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.visibility_outlined,
                      size: 18, color: AppTheme.sienna)),
              title: Text('profile_visibility'.tr, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
              subtitle: Text(
                  _profileVisible
                      ? 'Your profile is public'
                      : 'Your profile is private',
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              value: _profileVisible,
              onChanged: (v) {
                setState(() => _profileVisible = v);
                _updatePrivacy();
              },
              activeThumbColor: AppTheme.sienna,
              activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
            ),
            const CustomerDivider(),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: AppTheme.siennaBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.contacts_outlined,
                      size: 18, color: AppTheme.sienna)),
              title: Text('contact_visibility'.tr, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
              subtitle: Text(
                  _contactVisible
                      ? 'Contact info is visible'
                      : 'Contact info is hidden',
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              value: _contactVisible,
              onChanged: (v) {
                setState(() => _contactVisible = v);
                _updatePrivacy();
              },
              activeThumbColor: AppTheme.sienna,
              activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
            ),
          ]),
          const SizedBox(height: 24),
          SectionTitle(title: 'security'.tr),
          const SizedBox(height: 10),
          CustomerCard(children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color: _twoFaEnabled
                          ? AppTheme.successBg
                          : AppTheme.siennaBg,
                      borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.verified_user_outlined,
                      size: 18,
                      color:
                          _twoFaEnabled ? AppTheme.success : AppTheme.sienna)),
              title: Text('two_factor'.tr, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
              subtitle: Text(
                  _twoFaEnabled
                      ? 'Enabled via ${_twoFaMethod.toUpperCase()}'
                      : 'Not enabled',
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              trailing: Switch(
                value: _twoFaEnabled,
                onChanged: (_) => _toggle2FA(),
                activeColor: AppTheme.sienna,
                activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          SectionTitle(title: 'legal'.tr),
          const SizedBox(height: 10),
          CustomerCard(children: [
            CustomerTile(
                icon: Icons.description_outlined,
                title: 'terms_of_service'.tr,
                onTap: () => _showLegal(context, 'terms_of_service'.tr)),
            const CustomerDivider(),
            CustomerTile(
                icon: Icons.policy_outlined,
                title: 'privacy_policy'.tr,
                onTap: () => _showLegal(context, 'privacy_policy'.tr)),
          ]),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              icon: const Icon(Icons.delete_outline),
              label: Text('delete_account'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
  }

  void _showLegal(BuildContext context, String title) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title),
            content: SingleChildScrollView(
                child: Text(
                    title == 'terms_of_service'.tr
                        ? 'terms_body'.tr
                        : 'privacy_body'.tr,
                    style: const TextStyle(fontSize: 13, height: 1.5))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('close'.tr))
            ],
          ));
}

class MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const MethodTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.siennaBg : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? AppTheme.sienna : AppTheme.hair(context),
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            Icon(icon,
                color: selected ? AppTheme.sienna : Colors.grey, size: 20),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppTheme.sienna : null)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.sienna, size: 18),
          ]),
        ),
      );
}

class CustomerDetailCard extends StatelessWidget {
  final List<CustomerDetailRow> rows;
  const CustomerDetailCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
          children: rows
              .asMap()
              .entries
              .map((e) => Column(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(children: [
                          Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: AppTheme.siennaBg,
                                  borderRadius: BorderRadius.circular(14)),
                              child: Icon(e.value.icon,
                                  size: 16, color: AppTheme.sienna)),
                          const SizedBox(width: 12),
                          Text(e.value.label, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                          const Spacer(),
                          Flexible(
                              child: Text(e.value.value,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                      .copyWith(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                        ])),
                    if (e.key < rows.length - 1)
                      Divider(height: 1, color: AppTheme.hair(context)),
                  ]))
              .toList()),
    );
  }
}

class CustomerDetailRow {
  final IconData icon;
  final String label, value;
  const CustomerDetailRow(this.icon, this.label, this.value);
}

class CustomerCard extends StatelessWidget {
  final List<Widget> children;
  const CustomerCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) =>
      PremiumCard(padding: EdgeInsets.zero, child: Column(children: children));
}

class CustomerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  const CustomerTile(
      {super.key,
      required this.icon,
      required this.title,
      required this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: AppTheme.siennaBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppTheme.sienna)),
        title: Text(title, style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
        onTap: onTap,
      );
}

class CustomerDivider extends StatelessWidget {
  const CustomerDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: 52, color: AppTheme.hair(context));
}

class CustomerTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const CustomerTabBarDelegate({required this.tabBar, required this.color});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext ctx, double shrinkOffset, bool overlaps) =>
      Container(color: color, child: tabBar);

  @override
  bool shouldRebuild(CustomerTabBarDelegate old) =>
      old.tabBar != tabBar || old.color != color;
}
