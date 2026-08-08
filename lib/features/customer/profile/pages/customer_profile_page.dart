import 'package:fluttertest/features/customer/profile/services/customer_profile_service.dart';
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
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/features/auth/widgets/account_action_flow.dart';
import 'package:fluttertest/features/customer/checkout/services/checkout_service.dart';
import 'package:fluttertest/features/customer/profile/widgets/widgets.dart';
import 'package:fluttertest/features/customer/checkout/services/address_service.dart';

class CustomerProfilePage extends StatefulWidget {
  final int initialTab;
  const CustomerProfilePage({super.key, this.initialTab = 0});
  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _authService = CustomerProfileService();
  final _addressService = AddressService();

  String _fullName = '', _email = '', _role = '';
  bool _loading = true;
  List<dynamic> _addresses = [];
  bool _addrsLoading = true;

  bool _twoFaEnabled = false;
  String _twoFaMethod = '';
  bool _phoneVerified = false;

  bool _profileVisible = true;
  bool _contactVisible = true;

  @override
  void initState() {
    super.initState();
    _tab =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
    _loadUser();
    _loadAddresses();
    _load2FA();
    _loadPrivacy();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final fullName = await SecureStorageService.getFullName() ?? '';
    final email = await SecureStorageService.getEmail() ?? '';
    final role = await SecureStorageService.getRole() ?? 'customer';
    if (mounted) {
      setState(() {
        _fullName = fullName;
        _email = email;
        _role = role;
        _loading = false;
      });
    }
  }

  Future<void> _loadAddresses() async {
    setState(() => _addrsLoading = true);
    try {
      final data = await _addressService.getMyAddresses();
      if (mounted)
        setState(() {
          _addresses = data;
          _addrsLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _addrsLoading = false);
    }
  }

  Future<void> _load2FA() async {
    try {
      final data = await _authService.get2FAStatus();
      final twoFaEnabled = data['twoFaEnabled'] == true;
      final phoneVerified = data['phoneVerified'] == true;
      final methods = (data['availableTwoFaMethods'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const <String>[];
      if (mounted) {
        setState(() {
          _twoFaEnabled = twoFaEnabled;
          _phoneVerified = phoneVerified;
          _twoFaMethod = methods.contains('sms')
              ? 'email + sms'
              : (data['twoFaMethod']?.toString() ?? '');
        });
      }
    } catch (_) {
      final twoFaEnabled = await SecureStorageService.isTwoFaEnabled();
      final twoFaMethod = await SecureStorageService.getTwoFaMethod() ?? '';
      final phoneVerified = await SecureStorageService.isPhoneVerified();
      if (mounted) {
        setState(() {
          _twoFaEnabled = twoFaEnabled;
          _twoFaMethod =
              phoneVerified && twoFaEnabled ? 'email + sms' : twoFaMethod;
          _phoneVerified = phoneVerified;
        });
      }
    }
  }

  Future<void> _loadPrivacy() async {
    try {
      final data = await _authService.getPrivacy();
      if (mounted) {
        setState(() {
          _profileVisible = data['profileVisible'] == true;
          _contactVisible = data['contactVisible'] == true;
        });
      }
    } catch (_) {}
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
              borderRadius: BorderRadius.circular(AppTheme.radius)),
          title: Text('disable_2fa'.tr),
          content: const Text(
              'Are you sure you want to disable two-factor authentication?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr)),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: Text('disable'.tr),
            ),
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
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } else {
      await _show2FASetup();
    }
  }

  Future<void> _show2FASetup() async {
    var phoneVerified = await SecureStorageService.isPhoneVerified();
    try {
      final data = await _authService.get2FAStatus();
      phoneVerified = data['phoneVerified'] == true;
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius)),
        title: Text('enable_2fa_title'.tr),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('two_fa_enable_info'.tr),
              const SizedBox(height: 12),
              Row(children: [
                Icon(phoneVerified ? Icons.check_circle : Icons.info_outline,
                    size: 18,
                    color: phoneVerified ? AppTheme.success : AppTheme.warning),
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
              onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _authService.setup2FA('email');
                await SecureStorageService.write('twoFaEnabled', 'true');
                await SecureStorageService.write('twoFaMethod', 'email');
                if (mounted) {
                  setState(() {
                    _twoFaEnabled = true;
                    _phoneVerified = phoneVerified;
                    _twoFaMethod = phoneVerified ? 'email + sms' : 'email';
                  });
                }
                _snack('2FA enabled');
              } catch (e) {
                _snack(e.toString().replaceFirst('Exception: ', ''),
                    error: true);
              }
            },
            child: Text('enable'.tr,
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePrivacy() async {
    try {
      await _authService.updatePrivacy(
          profileVisible: _profileVisible, contactVisible: _contactVisible);
    } catch (_) {}
  }

  void _showAddAddress() {
    final fn = TextEditingController(),
        ph = TextEditingController(),
        st = TextEditingController(),
        ci = TextEditingController(),
        sc = TextEditingController(),
        po = TextEditingController(),
        co = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
          builder: (ctx, setS) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                  decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLg))),
                  padding: const EdgeInsets.all(AppTheme.screenPad),
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppTheme.hair(context),
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('saved_addresses'.tr,
                        style: AppTextStyle.h3(color: AppTheme.ink(context))),
                    const SizedBox(height: 16),
                    FI(fn, 'full_name'.tr),
                    FI(ph, 'phone_number'.tr, keyboard: TextInputType.phone),
                    FI(st, 'address'.tr),
                    Row(children: [
                      Expanded(child: FI(ci, 'City *')),
                      const SizedBox(width: 12),
                      Expanded(child: FI(sc, 'State'))
                    ]),
                    Row(children: [
                      Expanded(
                          child: FI(po, 'Postal Code',
                              keyboard: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: FI(co, 'country'.tr))
                    ]),
                    const SizedBox(height: 8),
                    SiennaButton(
                      label: 'save'.tr,
                      loading: saving,
                      icon: Icons.location_on_outlined,
                      onTap: () async {
                        if (fn.text.isEmpty ||
                            ph.text.isEmpty ||
                            st.text.isEmpty ||
                            ci.text.isEmpty ||
                            co.text.isEmpty) {
                          _snack('please_fill_all'.tr, error: true);
                          return;
                        }
                        setS(() => saving = true);
                        try {
                          await _addressService.addAddress(
                              fullName: fn.text,
                              phoneNumber: ph.text,
                              street: st.text,
                              city: ci.text,
                              state: sc.text,
                              postalCode: po.text,
                              country: co.text);
                          if (mounted) {
                            Navigator.pop(ctx);
                            _loadAddresses();
                            _snack('Address added!');
                          }
                        } catch (e) {
                          setS(() => saving = false);
                          _snack(e.toString().replaceFirst('Exception: ', ''),
                              error: true);
                        }
                      },
                    ),
                  ])),
                ),
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body:
              Center(child: CircularProgressIndicator(color: AppTheme.sienna)));
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
              ),
            ),
          ),
        ],
        body: TabBarView(controller: _tab, children: [
          _buildProfileTab(),
          _buildSettingsTab(),
          _buildPrivacyTab(),
        ]),
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
          RoleAvatar(imagePath: 'assets/images/customer.png', fallback: _fullName, size: 76),
          const SizedBox(height: 14),
          Text(_fullName,
              style: AppTextStyle.h3(color: AppTheme.ink(context))
                  .copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(_email,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 10),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                    color: AppTheme.accentSoft(context),
                    borderRadius: BorderRadius.circular(999)),
                child: Text('private_client'.tr,
                    style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
          ]),
        ]),
      );

  Widget _buildProfileTab() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        Text('account_info'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            _InfoRow('full_name'.tr, _fullName),
            Divider(height: 1, color: AppTheme.hair(context)),
            _InfoRow('email'.tr, _email),
            Divider(height: 1, color: AppTheme.hair(context)),
            _InfoRow('role'.tr, _role.toUpperCase()),
          ]),
        ),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('saved_addresses'.tr,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          GestureDetector(
            onTap: _showAddAddress,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add, size: 14, color: AppTheme.sienna),
                const SizedBox(width: 4),
                Text('add'.tr,
                    style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        if (_addrsLoading)
          const Center(child: CircularProgressIndicator(color: AppTheme.sienna))
        else if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration(context),
            child: Column(children: [
              Icon(Icons.location_off_outlined,
                  size: 36, color: AppTheme.muted(context)),
              const SizedBox(height: 8),
              Text('no_addresses'.tr,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              const SizedBox(height: 12),
              GestureDetector(
                  onTap: _showAddAddress,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: AppTheme.siennaSoft,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('add_first_address'.tr,
                          style:
                              AppTextStyle.eyebrow(color: AppTheme.sienna)))),
            ]),
          )
        else
          ..._addresses.map((addr) {
            final id = addr['addressId'] is int
                ? addr['addressId'] as int
                : int.tryParse(addr['addressId'].toString()) ?? 0;
            final isDefault = addr['isDefault'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.cardDecoration(context).copyWith(
                border: Border.all(
                    color: isDefault
                        ? AppTheme.sienna.withValues(alpha: 0.5)
                        : AppTheme.hair(context),
                    width: isDefault ? 1.5 : 1),
              ),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: isDefault
                            ? AppTheme.siennaSoft
                            : AppTheme.surface2(context),
                        borderRadius: BorderRadius.circular(28)),
                    child: Icon(Icons.location_on_outlined,
                        color: isDefault
                            ? AppTheme.sienna
                            : AppTheme.muted(context),
                        size: 17)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      if (addr['fullName'] != null)
                        Text(addr['fullName'].toString(),
                            style: AppTextStyle.bodySmall(
                                    color: AppTheme.ink(context))
                                .copyWith(fontWeight: FontWeight.w600)),
                      Text(
                          '${addr['street'] ?? ''}, ${addr['city'] ?? ''}, ${addr['country'] ?? ''}',
                          style: AppTextStyle.eyebrow(
                              color: AppTheme.muted(context))),
                      if (isDefault) ...[
                        const SizedBox(height: 4),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppTheme.siennaSoft,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('default'.tr,
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.sienna)))
                      ],
                    ])),
                GestureDetector(
                  onTap: () {
                    setState(() =>
                        _addresses.removeWhere((a) => a['addressId'] == id));
                  },
                  child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                          color: AppTheme.dangerBg,
                          borderRadius:
                              BorderRadius.circular(28)),
                      child: const Icon(Icons.delete_outline,
                          size: 14, color: AppTheme.danger)),
                ),
              ]),
            );
          }),
        const SizedBox(height: 32),
        SiennaButton(
          label: 'log_out'.tr,
          variant: AppButtonVariant.secondary,
          icon: Icons.logout_rounded,
          height: 50,
          onTap: () => Navigator.pushReplacementNamed(context, '/logout'),
        ),
        const SizedBox(height: 12),
        SiennaButton(
          label: 'deactivate_account'.tr,
          variant: AppButtonVariant.ghost,
          icon: Icons.pause_circle_outline_rounded,
          height: 50,
          onTap: () async {
            final done = await AccountActionFlow.run(context, 'DEACTIVATE');
            if (done && context.mounted) {
              Navigator.pushReplacementNamed(context, '/logout');
            }
          },
        ),
        const SizedBox(height: 12),
        SiennaButton(
          label: 'delete_account'.tr,
          variant: AppButtonVariant.destructive,
          icon: Icons.delete_outline_rounded,
          height: 50,
          onTap: () async {
            final done = await AccountActionFlow.run(context, 'DELETE');
            if (done && context.mounted) {
              Navigator.pushReplacementNamed(context, '/logout');
            }
          },
        ),
      ]);

  Widget _buildSettingsTab() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        Text('appearance'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
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
        Text('account'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            SettingsTile(Icons.lock_outline_rounded, 'change_password'.tr,
                onTap: () => showChangePasswordSheet(context)),
            Divider(height: 1, color: AppTheme.hair(context)),
            SettingsTile(Icons.notifications_outlined, 'notifications'.tr,
                onTap: () => showNotificationsSheet(context)),
            Divider(height: 1, color: AppTheme.hair(context)),
            GetBuilder<LanguageController>(
                builder: (lc) => SettingsTile(
                      Icons.language_outlined,
                      'language'.tr,
                      trailing: Text(lc.displayName,
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.muted(context))),
                      onTap: () => showLanguageSheet(context),
                    )),
          ]),
        ),
      ]);

  Widget _buildPrivacyTab() =>
      ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), children: [
        Text('data_privacy'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppTheme.accentSoft(context),
                      borderRadius: BorderRadius.circular(28)),
                  child: const Icon(Icons.visibility_outlined,
                      size: 16, color: AppTheme.sienna)),
              title: Text('profile_visibility'.tr,
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(_profileVisible ? 'Public' : 'Private',
                  style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              value: _profileVisible,
              onChanged: (v) {
                setState(() => _profileVisible = v);
                _updatePrivacy();
              },
              activeThumbColor: AppTheme.sienna,
              activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
            ),
            Divider(height: 1, color: AppTheme.hair(context)),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              secondary: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: AppTheme.accentSoft(context),
                      borderRadius: BorderRadius.circular(28)),
                  child: const Icon(Icons.contacts_outlined,
                      size: 16, color: AppTheme.sienna)),
              title: Text('contact_visibility'.tr,
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w500)),
              subtitle: Text(_contactVisible ? 'Visible' : 'Hidden',
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
        ),
        const SizedBox(height: 24),
        Text('security'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
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
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(Icons.verified_user_outlined,
                  size: 16,
                  color: _twoFaEnabled
                      ? (AppTheme.isDark(context)
                          ? AppTheme.darkSuccess
                          : AppTheme.success)
                      : AppTheme.sienna),
            ),
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
                      : AppTheme.muted(context)),
            ),
            trailing: Switch(
              value: _twoFaEnabled,
              onChanged: (_) => _toggle2FA(),
              activeColor: AppTheme.sienna,
              activeTrackColor: AppTheme.sienna.withValues(alpha: 0.3),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('legal'.tr,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 10),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(children: [
            SettingsTile(Icons.description_outlined, 'terms_of_service'.tr,
                onTap: () => _showLegal('Terms of Service')),
            Divider(height: 1, color: AppTheme.hair(context)),
            SettingsTile(Icons.policy_outlined, 'privacy_policy'.tr,
                onTap: () => _showLegal('Privacy Policy')),
          ]),
        ),
      ]);

  void _showLegal(String title) => showDialog(
      context: context,
      builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius)),
            title: Text(title),
            content: SingleChildScrollView(
                child: Text(
                    title == 'Terms of Service'
                        ? 'By using IBAL, you agree to our terms of service. All policies are subject to broker terms.'
                        : 'IBAL collects personal data to facilitate purchases. Data is stored securely and never sold.',
                    style: const TextStyle(fontSize: 13, height: 1.5))),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('close'.tr))
            ],
          ));

  Widget _InfoRow(String label, String value) => Padding(
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
}
