import 'package:fluttertest/features/auth/services/signup_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertest/core/animations/app_animations.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/gradient_button.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/country_phone_widgets.dart';
import 'package:fluttertest/features/admin/users/services/user_admin_service.dart';

class CreateAdminPage extends StatefulWidget {
  const CreateAdminPage({super.key});
  @override
  State<CreateAdminPage> createState() => _CreateAdminPageState();
}

class _CreateAdminPageState extends State<CreateAdminPage>
    with TickerProviderStateMixin, AppAnimationsMixin {
  final _service = UserAdminService();
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  int? _selectedCountryId;
  List<Map<String, String>> _countries = [];

  @override
  void initState() {
    super.initState();
    initAnimations();
    startAnimations();
    _loadCountries();
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _username,
      _email,
      _phone,
      _password,
      _confirm
    ]) {
      c.dispose();
    }
    disposeAnimations();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final data = await SignupService().getAllCountries();
      setState(() {
        _countries = data
            .map<Map<String, String>>((item) => {
                  'name': item['countryName']?.toString() ?? '',
                  'code': item['code']?.toString() ?? '',
                  'country_id': (item['countryId'] ??
                          item['country_id'] ??
                          item['id'] ??
                          '')
                      .toString(),
                })
            .toList();
      });
    } catch (e) {
      _snack('Failed to load countries');
    }
  }

  String get _countryCode {
    if (_selectedCountryId == null) return '';
    return _countries.firstWhere(
          (c) => c['country_id'] == _selectedCountryId.toString(),
          orElse: () => {'code': ''},
        )['code'] ??
        '';
  }

  String get _countryName {
    if (_selectedCountryId == null) return '';
    return _countries.firstWhere(
          (c) => c['country_id'] == _selectedCountryId.toString(),
          orElse: () => {'name': ''},
        )['name'] ??
        '';
  }

  Future<void> _submit() async {
    if (_fullName.text.isEmpty ||
        _username.text.isEmpty ||
        _email.text.isEmpty ||
        _password.text.isEmpty ||
        _selectedCountryId == null) {
      _snack('Please fill in all fields');
      return;
    }
    if (_password.text != _confirm.text) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.createAdmin(
        fullName: _fullName.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
        confirm: _confirm.text,
        countryId: _selectedCountryId!,
        countryName: _countryName,
        countryCode: _countryCode,
        phoneNumber: '$_countryCode${_phone.text}',
      );
      if (!mounted) return;
      _snack('Admin account created successfully');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.ink(context)),
        title: Text(
          'Create Admin',
          style: AppTextStyle.h3(color: AppTheme.ink(context)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: animatedSection(
          index: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.sienna,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Admin Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'This account will have admin access.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Account Details'),
              const SizedBox(height: 14),
              PremiumField(
                label: 'Full Name',
                hint: 'Enter full name',
                prefixIcon: Icons.badge_outlined,
                controller: _fullName,
              ),
              const SizedBox(height: 14),
              PremiumField(
                label: 'Username',
                hint: 'Enter username',
                prefixIcon: Icons.alternate_email,
                controller: _username,
              ),
              const SizedBox(height: 14),
              PremiumField(
                label: 'Email',
                hint: 'Enter email address',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _email,
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Password'),
              const SizedBox(height: 14),
              PremiumField(
                label: 'Password',
                hint: 'Enter password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                controller: _password,
              ),
              const SizedBox(height: 14),
              PremiumField(
                label: 'Confirm Password',
                hint: 'Re-enter password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: true,
                controller: _confirm,
              ),
              const SizedBox(height: 28),
              const SectionTitle(title: 'Country & Phone Number'),
              const SizedBox(height: 14),
              CountryDropdown(
                countries: _countries,
                selectedCountry: _selectedCountryId?.toString(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedCountryId =
                        val.isNotEmpty ? int.tryParse(val) : null;
                  });
                },
              ),
              const SizedBox(height: 14),
              PhoneField(
                controller: _phone,
                countryCode: _countryCode,
              ),
              const SizedBox(height: 32),
              GradientButton(
                label: 'Create Admin Account',
                loading: _loading,
                onTap: _submit,
                icon: Icons.admin_panel_settings_outlined,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
