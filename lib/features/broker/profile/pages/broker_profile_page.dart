import 'package:fluttertest/features/broker/profile/services/broker_profile_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/settings_sheets.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/widgets/ibal_logo.dart';
import 'package:fluttertest/core/widgets/role_avatar.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/theme_mode_selector.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_service.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/widgets/account_action_flow.dart';
import 'package:fluttertest/features/broker/profile/widgets/widgets.dart';
import 'package:fluttertest/features/broker/dashboard/services/broker_dashboard_service.dart';

class BrokerProfilePage extends StatefulWidget {
  const BrokerProfilePage({super.key});
  @override
  State<BrokerProfilePage> createState() => _BrokerProfilePageState();
}

class _BrokerProfilePageState extends State<BrokerProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _service = BrokerDashboardService();
  final _authService = BrokerProfileService();

  String _fullName = '',
      _email = '',
      _company = '',
      _license = '',
      _taxId = '',
      _address = '',
      _website = '';
  bool _loading = true;
  bool _twoFaEnabled = false;
  String _twoFaMethod = '';
  bool _phoneVerified = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final fullName = await SecureStorageService.getFullName() ?? '';
    final email = await SecureStorageService.getEmail() ?? '';
    final twoFaEnabled = await SecureStorageService.isTwoFaEnabled();
    final twoFaMethod = await SecureStorageService.getTwoFaMethod() ?? '';
    final phoneVerified = await SecureStorageService.isPhoneVerified();
    if (mounted) {
      setState(() {
        _fullName = fullName;
        _email = email;
        _twoFaEnabled = twoFaEnabled;
        _phoneVerified = phoneVerified;
        _twoFaMethod =
            phoneVerified && twoFaEnabled ? 'email + sms' : twoFaMethod;
      });
    }
    try {
      final status = await _authService.get2FAStatus();
      final methods = (status['availableTwoFaMethods'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const <String>[];
      if (mounted) {
        setState(() {
          _twoFaEnabled = status['twoFaEnabled'] == true;
          _phoneVerified = status['phoneVerified'] == true;
          _twoFaMethod = methods.contains('sms')
              ? 'email + sms'
              : (status['twoFaMethod']?.toString() ?? '');
        });
      }
    } catch (_) {}
    try {
      final data = await _service.getBrokerDetails();
      if (mounted) {
        setState(() {
          _company = data['companyName']?.toString() ?? '';
          _license = data['licenseNumber']?.toString() ?? '';
          _taxId = data['taxId']?.toString() ?? '';
          _address = data['address']?.toString() ?? '';
          _website = data['websiteUrl']?.toString() ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.danger : AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
      ));

  Future<void> _toggle2FA() async {
    if (_twoFaEnabled) {
      final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
                title: Text('disable_2fa'.tr),
                content: const Text(
                    'Are you sure you want to disable two-factor authentication?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('cancel'.tr)),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.danger),
                      child: Text('disable'.tr)),
                ],
              ));
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
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } else {
      _show2FASetup();
    }
  }

  void _show2FASetup() async {
    var phoneVerified = await SecureStorageService.isPhoneVerified();
    try {
      final status = await _authService.get2FAStatus();
      phoneVerified = status['phoneVerified'] == true;
    } catch (_) {}
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
              title: Text('enable_2fa_title'.tr),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('two_fa_enable_info'.tr),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(
                          phoneVerified
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 18,
                          color: phoneVerified
                              ? AppTheme.success
                              : AppTheme.warning),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              phoneVerified
                                  ? 'phone_verified_choice_at_login'.tr
                                  : 'phone_not_verified_email_only'.tr,
                              style: AppTextStyle.bodySmall(
                                  color: AppTheme.muted(context)))),
                    ]),
                    if (!phoneVerified) ...[
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(context, '/verify-phone');
                          },
                          child: Text('verify_phone_now'.tr)),
                    ],
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('cancel'.tr)),
                TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await _authService.setup2FA('email');
                        await SecureStorageService.write(
                            'twoFaEnabled', 'true');
                        await SecureStorageService.write(
                            'twoFaMethod', 'email');
                        if (mounted) {
                          setState(() {
                            _twoFaEnabled = true;
                            _phoneVerified = phoneVerified;
                            _twoFaMethod =
                                phoneVerified ? 'email + sms' : 'email';
                          });
                        }
                        _snack('2FA enabled');
                      } catch (e) {
                        _snack(e.toString().replaceFirst('Exception: ', ''),
                            error: true);
                      }
                    },
                    child: Text('enable'.tr,
                        style: TextStyle(fontWeight: FontWeight.w700))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(color: AppTheme.sienna)));
    }
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
              pinned: true,
              delegate: TabDel(
                  color: AppTheme.surface(context),
                  tabBar: TabBar(
                    controller: _tab,
                    labelColor: AppTheme.sienna,
                    unselectedLabelColor: AppTheme.muted(context),
                    indicatorColor: AppTheme.sienna,
                    indicatorWeight: 2,
                    dividerColor: AppTheme.hair(context),
                    tabs: const [
                      Tab(text: 'Profile'),
                      Tab(text: 'Settings'),
                      Tab(text: 'Privacy')
                    ],
                  ))),
        ],
        body: TabBarView(
            controller: _tab,
            children: [_buildProfile(), _buildSettings(), _buildPrivacy()]),
      ),
    );
  }

  Widget _buildHeader() => AuroraBackdrop(
        orbAlignment: const Alignment(0.8, -0.6),
        secondaryOrbAlignment: const Alignment(-0.7, 0.8),
        child: Padding(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 24,
              left: AppTheme.screenPad,
              right: AppTheme.screenPad),
          child: Column(children: [
            const IbalLogo(width: 100),
            const SizedBox(height: 16),
            RoleAvatar(imagePath: 'assets/images/broker.png', fallback: _fullName, size: 80, glow: true),
            const SizedBox(height: 14),
            Text(_fullName,
                style: AppTextStyle.h3(color: AppTheme.ink(context))
                    .copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_email,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: AppTheme.brandGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.verified_rounded,
                    size: 12, color: Colors.white),
                const SizedBox(width: 5),
                Text('verified_broker'.tr,
                    style: AppTextStyle.eyebrow(color: Colors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      );

  Widget _buildProfile() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sectionLabel('company'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              _row('company_name'.tr, _company),
              if (_license.isNotEmpty) ...[
                Divider(height: 1, color: AppTheme.hair(context)),
                _row('license'.tr, _license)
              ],
              if (_taxId.isNotEmpty) ...[
                Divider(height: 1, color: AppTheme.hair(context)),
                _row('tax_id'.tr, _taxId)
              ],
              if (_address.isNotEmpty) ...[
                Divider(height: 1, color: AppTheme.hair(context)),
                _row('address'.tr, _address)
              ],
              if (_website.isNotEmpty) ...[
                Divider(height: 1, color: AppTheme.hair(context)),
                _row('website'.tr, _website)
              ],
            ])),
        const SizedBox(height: 24),
        _sectionLabel('account'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              _row('full_name'.tr, _fullName),
              Divider(height: 1, color: AppTheme.hair(context)),
              _row('email'.tr, _email),
            ])),
        const SizedBox(height: 32),
        SiennaButton(
          label: 'log_out'.tr,
          icon: Icons.logout_rounded,
          variant: AppButtonVariant.secondary,
          height: 50,
          onTap: () => Navigator.pushReplacementNamed(context, '/logout'),
        ),
        const SizedBox(height: 10),
        SiennaButton(
          label: 'deactivate_account'.tr,
          icon: Icons.pause_circle_outline_rounded,
          variant: AppButtonVariant.ghost,
          height: 50,
          onTap: () async {
            final done = await AccountActionFlow.run(context, 'DEACTIVATE');
            if (done && mounted) {
              Navigator.pushReplacementNamed(context, '/logout');
            }
          },
        ),
        const SizedBox(height: 10),
        SiennaButton(
          label: 'delete_account'.tr,
          icon: Icons.delete_outline_rounded,
          variant: AppButtonVariant.destructive,
          height: 50,
          onTap: () async {
            final done = await AccountActionFlow.run(context, 'DELETE');
            if (done && mounted) {
              Navigator.pushReplacementNamed(context, '/logout');
            }
          },
        ),
      ]);

  Widget _buildSettings() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sectionLabel('appearance'.tr),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.cardDecoration(context),
          child: Row(children: [
            Icon(Icons.brightness_6_outlined, color: AppTheme.sienna, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('theme'.tr,
                        style:
                            AppTextStyle.bodySmall(color: AppTheme.ink(context))
                                .copyWith(fontWeight: FontWeight.w600)),
                    Text('theme_auto_subtitle'.tr,
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ]),
            ),
            const SizedBox(width: 8),
            const ThemeModeSelector(),
          ]),
        ),
        const SizedBox(height: 24),
        _sectionLabel('account'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              _tile(Icons.lock_outline_rounded, 'change_password'.tr,
                  onTap: () => showChangePasswordSheet(context)),
              Divider(height: 1, color: AppTheme.hair(context)),
              GetBuilder<LanguageController>(
                  builder: (lc) => _tile(Icons.language_outlined, 'language'.tr,
                      trailing: Text(lc.displayName,
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.muted(context))),
                      onTap: () => showLanguageSheet(context))),
            ])),
      ]);

  Widget _buildPrivacy() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sectionLabel('security'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: _twoFaEnabled
                          ? (AppTheme.isDark(context)
                              ? AppTheme.darkSuccess.withValues(alpha: 0.14)
                              : AppTheme.successBg)
                          : AppTheme.accentSoft(context),
                      borderRadius: BorderRadius.circular(28)),
                  child: Icon(Icons.verified_user_outlined,
                      size: 16,
                      color: _twoFaEnabled
                          ? (AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success)
                          : AppTheme.sienna)),
              title: Text('two_factor'.tr,
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(
                  _twoFaEnabled
                      ? 'Enabled via ${(_phoneVerified ? 'email + sms' : _twoFaMethod).toUpperCase()}'
                      : 'Not enabled',
                  style: AppTextStyle.eyebrow(
                      color: _twoFaEnabled
                          ? (AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success)
                          : AppTheme.muted(context))),
              trailing: Switch(
                  value: _twoFaEnabled,
                  onChanged: (_) => _toggle2FA(),
                  activeThumbColor: AppTheme.sienna,
                  activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3)),
            )),
        const SizedBox(height: 24),
        _sectionLabel('legal'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              _tile(Icons.description_outlined, 'terms_of_service'.tr,
                  onTap: () {}),
              Divider(height: 1, color: AppTheme.hair(context)),
              _tile(Icons.policy_outlined, 'privacy_policy'.tr, onTap: () {}),
            ])),
      ]);

  Widget _sectionLabel(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child:
          Text(t, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))));

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Text(label,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          const Spacer(),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis)),
        ]),
      );

  Widget _tile(IconData icon, String label,
          {Widget? trailing, required VoidCallback onTap}) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AppTheme.accentSoft(context),
                borderRadius: BorderRadius.circular(28)),
            child: Icon(icon, size: 16, color: AppTheme.sienna)),
        title: Text(label,
            style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                .copyWith(fontWeight: FontWeight.w500, fontSize: 13)),
        trailing: trailing ??
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppTheme.muted(context)),
        onTap: onTap,
      );
}
