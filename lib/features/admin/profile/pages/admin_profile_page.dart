import 'package:fluttertest/features/auth/services/two_fa_service.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/utils/settings_sheets.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/widgets/ibal_logo.dart';
import 'package:fluttertest/core/widgets/role_avatar.dart';
import 'package:fluttertest/core/widgets/theme_mode_selector.dart';
import 'package:fluttertest/features/admin/profile/services/admin_profile_service.dart';
import 'package:fluttertest/features/admin/users/pages/create_admin_page.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});
  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _authService = AdminProfileService();
  final _twoFaService = TwoFaService();
  String _fullName = '', _email = '', _role = '';
  bool _loading = true;
  bool _twoFaEnabled = false;
  String _twoFaMethod = '';

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
    final role = await SecureStorageService.getRole() ?? '';
    final twoFaEnabled = await SecureStorageService.isTwoFaEnabled() ?? false;
    final twoFaMethod = await SecureStorageService.getTwoFaMethod() ?? '';

    if (mounted) {
      setState(() {
        _fullName = fullName;
        _email = email;
        _role = role;
        _twoFaEnabled = twoFaEnabled;
        _twoFaMethod = twoFaMethod;
      });
    }

    try {
      final data = await AdminProfileService().getAdminProfile();
      if (mounted)
        setState(() {
          _fullName = data['fullName']?.toString() ?? _fullName;
          _email = data['email']?.toString() ?? _email;
          _role = data['role']?.toString() ?? _role;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isSuperAdmin => _role.toLowerCase() == 'superadmin';

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
      _snack('Admin accounts require 2FA and it cannot be disabled.');
      return;
    } else {
      String selected = 'email';
      await showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
              builder: (ctx, setS) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius)),
                    title: Text('enable_2fa_title'.tr),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          'Admin accounts require 2FA on every login. Choose delivery method:'),
                      const SizedBox(height: 16),
                      _MethodTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          selected: selected == 'email',
                          onTap: () => setS(() => selected = 'email')),
                      const SizedBox(height: 8),
                      _MethodTile(
                          icon: Icons.sms_outlined,
                          label: 'SMS',
                          selected: selected == 'sms',
                          onTap: () => setS(() => selected = 'sms')),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('cancel'.tr)),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await _twoFaService.setup2FA(selected);
                            await SecureStorageService.write(
                                'twoFaEnabled', 'true');
                            await SecureStorageService.write(
                                'twoFaMethod', selected);
                            if (mounted)
                              setState(() {
                                _twoFaEnabled = true;
                                _twoFaMethod = selected;
                              });
                            _snack('2FA enabled via $selected!');
                          } catch (e) {
                            _snack(e.toString().replaceFirst('Exception: ', ''),
                                error: true);
                          }
                        },
                        child: Text('enable'.tr,
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: AppTheme.sienna)));
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
              pinned: true,
              delegate: _TabDel(
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
                      Tab(text: 'Security')
                    ],
                  ))),
        ],
        body: TabBarView(
            controller: _tab,
            children: [_buildProfile(), _buildSettings(), _buildSecurity()]),
      ),
    );
  }

  Widget _buildHeader() => Container(
        color: AppTheme.surface(context),
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 16,
            bottom: 20,
            left: AppTheme.screenPad,
            right: AppTheme.screenPad),
        child: Column(children: [
          const IbalLogo(width: 100),
          const SizedBox(height: 16),
          RoleAvatar(imagePath: 'assets/images/admin.png', fallback: _fullName.isNotEmpty ? _fullName : 'OP', size: 76),
          const SizedBox(height: 14),
          Text(_fullName,
              style: AppTextStyle.h3(color: AppTheme.ink(context))
                  .copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(_email,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 10),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: AppTheme.accentSoft(context),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(_isSuperAdmin ? 'Superadmin' : 'Admin',
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
        ]),
      );

  Widget _buildProfile() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sLabel('account_info'.tr),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              _row('full_name'.tr, _fullName),
              Divider(height: 1, color: AppTheme.hair(context)),
              _row('email'.tr, _email),
              Divider(height: 1, color: AppTheme.hair(context)),
              _row('role'.tr, _role.toUpperCase()),
            ])),
        if (_isSuperAdmin) ...[
          const SizedBox(height: 24),
          _sLabel('superadmin_label'.tr),
          Container(
              decoration: AppTheme.cardDecoration(context),
              child: Column(children: [
                _tile(Icons.person_add_outlined, 'create_admin'.tr,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateAdminPage()))),
                Divider(height: 1, color: AppTheme.hair(context)),
                _tile(Icons.manage_accounts_outlined, 'Role permissions',
                    onTap: () {}),
                Divider(height: 1, color: AppTheme.hair(context)),
                _tile(Icons.history_outlined, 'Audit log', onTap: () {}),
              ])),
        ],
        const SizedBox(height: 32),
        GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/logout'),
            child: Container(
                height: 50,
                decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.hair(context)),
                    borderRadius: BorderRadius.circular(28)),
                child: Center(
                    child: Text('log_out'.tr,
                        style: AppTextStyle.button(
                            color: AppTheme.isDark(context)
                                ? AppTheme.darkDanger
                                : AppTheme.danger))))),
      ]);

  Widget _buildSettings() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sLabel('appearance'.tr),
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
                        style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text('theme_auto_subtitle'.tr,
                        style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                  ]),
            ),
            const SizedBox(width: 8),
            const ThemeModeSelector(),
          ]),
        ),
        const SizedBox(height: 24),
        _sLabel('account'.tr),
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

  Widget _buildSecurity() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        _sLabel('TWO-FACTOR AUTHENTICATION'),
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
                      ? 'Enabled via ${_twoFaMethod.toUpperCase()}'
                      : 'Not enabled — admin accounts should enable this',
                  style: AppTextStyle.eyebrow(
                      color: _twoFaEnabled
                          ? (AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success)
                          : AppTheme.warning)),
              trailing: Switch(
                  value: _twoFaEnabled,
                  onChanged: (_) => _toggle2FA(),
                  activeColor: AppTheme.sienna,
                  activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3)),
            )),
        const SizedBox(height: 24),
        _sLabel('SESSIONS'),
        Container(
            decoration: AppTheme.cardDecoration(context),
            child: _tile(Icons.devices_outlined, 'active_sessions'.tr,
                trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.accentSoft(context),
                        borderRadius: BorderRadius.circular(999)),
                    child: Text('1',
                        style: AppTextStyle.mono(
                            size: 11,
                            weight: FontWeight.w600,
                            color: AppTheme.sienna))),
                onTap: () {})),
      ]);

  Widget _sLabel(String t) => Padding(
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

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile(
      {required this.icon,
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
              color: selected ? AppTheme.siennaSoft : AppTheme.surface(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: selected ? AppTheme.sienna : AppTheme.hair(context),
                  width: selected ? 1.5 : 1)),
          child: Row(children: [
            Icon(icon,
                color: selected ? AppTheme.sienna : AppTheme.muted(context),
                size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(label,
                    style: AppTextStyle.bodySmall(
                            color: selected
                                ? AppTheme.sienna
                                : AppTheme.ink(context))
                        .copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400))),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.sienna, size: 18),
          ])));
}

class _TabDel extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const _TabDel({required this.tabBar, required this.color});
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(_, double s, bool __) => Container(color: color, child: tabBar);
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
