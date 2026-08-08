import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/animations/app_animations.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/file_upload_service.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/auth/widgets/widgets.dart';
import 'package:fluttertest/core/widgets/country_phone_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with TickerProviderStateMixin, AppAnimationsMixin {
  final _authService   = SignupService();
  final _uploadService = FileUploadService();
  final _api           = ApiService();

  final _email       = TextEditingController();
  final _password    = TextEditingController();
  final _confirm     = TextEditingController();
  final _name        = TextEditingController();
  final _phone       = TextEditingController();
  final _companyName = TextEditingController();
  final _license     = TextEditingController();
  final _tax         = TextEditingController();
  final _address     = TextEditingController();
  final _logo        = TextEditingController();
  final _idFront     = TextEditingController();
  final _idBack      = TextEditingController();
  final _website     = TextEditingController();

  bool _loading         = false;
  bool _acceptedTerms   = false;
  String? _uploadingField;

  String? _selectedRole;
  int? _selectedCountryId;
  List<Map<String, String>> _countries = [];
  bool _roleConfirmed = false;

  late AnimationController _formController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  final _emailRegex    = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{8,}$');

  @override
  void initState() {
    super.initState();
    initAnimations();
    startAnimations();
    _loadCountries();

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _formController.dispose();
    disposeAnimations();
    for (final c in [
      _email, _password, _confirm, _name, _phone,
      _companyName, _license, _tax, _address,
      _logo, _idFront, _idBack, _website,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _loadCountries() async {
    try {
      final data = await _authService.getAllCountries();
      setState(() {
        _countries = data.map<Map<String, String>>((item) => {
              'name':       item['countryName']?.toString() ?? '',
              'code':       item['code']?.toString() ?? '',
              'country_id': (item['countryId'] ?? item['country_id'] ??
                      item['id'] ?? '').toString(),
            }).toList();
      });
    } catch (_) {
      _snack('Failed to load countries');
    }
  }

  void _onContinue() {
    if (_selectedRole == null) { _snack('Please select a role'); return; }
    if (_selectedRole == 'admin') {
      _snack('Admin signup is not available from this screen');
      return;
    }
    setState(() => _roleConfirmed = true);
    _formController.forward(from: 0);
  }

  Future<void> _handleSignup() async {
    if (_loading) return;
    if (_name.text.isEmpty) { return _snack('Please enter a name'); }
    if (!_emailRegex.hasMatch(_email.text)) {
      return _snack('Email format is wrong');
    }
    if (!_passwordRegex.hasMatch(_password.text)) {
      return _snack(
          'Password needs 8+ chars with uppercase, lowercase, number & special char');
    }
    if (_password.text != _confirm.text) {
      return _snack('Passwords do not match');
    }
    if (_selectedCountryId == null) { return _snack('Please select a country'); }
    if (_selectedRole == 'broker') {
      if (_companyName.text.trim().isEmpty) {
        return _snack('Please enter company name');
      }
      if (_license.text.trim().isEmpty) {
        return _snack('Please enter license number');
      }
      if (_logo.text.trim().isEmpty) {
        return _snack('Please upload the company logo');
      }
      if (_idFront.text.trim().isEmpty || _idBack.text.trim().isEmpty) {
        return _snack('Please upload ID front and back documents');
      }
    }
    if (!_acceptedTerms) { return _snack('Please accept the terms and conditions'); }
    setState(() => _loading = true);
    try {
      if (_selectedRole == 'customer') {
        await _authService.userSignup(
          fullName:    _name.text.trim(),
          email:       _email.text.trim(),
          password:    _password.text,
          confirm:     _confirm.text,
          phoneNumber: '',
          countryId:   _selectedCountryId!,
          acceptedTerms: _acceptedTerms,
        );
      } else {
        await _authService.brokerSignup(
          fullName:     _name.text.trim(),
          email:        _email.text.trim(),
          password:     _password.text,
          confirm:      _confirm.text,
          phoneNumber:  '',
          countryId:    _selectedCountryId!,
          companyName:  _companyName.text.trim(),
          licenseNumber: _license.text.trim(),
          taxId:        _tax.text.trim(),
          address:      _address.text.trim(),
          logoUrl:      _logo.text.trim(),
          websiteUrl:   _website.text.trim(),
          idFrontUrl:   _idFront.text.trim(),
          idBackUrl:    _idBack.text.trim(),
          acceptedTerms: _acceptedTerms,
        );
      }
      if (mounted) Navigator.pushReplacementNamed(context, '/verify-email');
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppTextStyle.bodySmall(color: Colors.white)),
      backgroundColor: AppTheme.sienna,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28)),
    ));
  }

  Future<void> _uploadBrokerFile({
    required String field,
    required TextEditingController target,
    required String endpoint,
    required String accept,
  }) async {
    if (_uploadingField != null) return;
    setState(() => _uploadingField = field);
    try {
      final url = await _uploadService.pickAndUpload(
          endpoint: endpoint, accept: accept, auth: false);
      if (url != null && mounted) {
        setState(() => target.text = url);
        _snack('File uploaded');
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingField = null);
    }
  }

  Future<void> _openUploadedFile(String value) async {
    final url = _api.assetUrl(value);
    if (url.isEmpty) return;
    final opened = await launchUrl(Uri.parse(url),
        mode: LaunchMode.platformDefault);
    if (!opened && mounted) _snack('Could not open uploaded file');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_roleConfirmed) {
      return Scaffold(
        backgroundColor: AppTheme.bg(context),
        body: AuroraBackdrop(
          child: SafeArea(
            child: FadeTransition(
              opacity: s1Fade,
              child: SlideTransition(
                position: s1Slide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
                  child: _buildRoleSelection(),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: FadeTransition(
        opacity: s1Fade,
        child: SlideTransition(
          position: s1Slide,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(children: [
              _buildGradientHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                child: _buildForm(),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Role selection ────────────────────────────────────────────────────────

  Widget _buildRoleSelection() {
    return Column(children: [
      const SizedBox(height: 8),

      // Brand eyebrow
      Text(
        'IBAL',
        style: AppTextStyle.eyebrow(color: AppTheme.sienna).copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 3.0,
        ),
      ),

      const SizedBox(height: 20),

      Text(
        'role_selection'.tr,
        textAlign: TextAlign.center,
        style: AppTextStyle.h2(color: AppTheme.ink(context))
            .copyWith(fontWeight: FontWeight.w900),
      ),

      const SizedBox(height: 6),

      Text(
        'Choose how you\'ll use IBAL',
        textAlign: TextAlign.center,
        style: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
      ),

      const SizedBox(height: 28),

      IllustrationRoleCard(
        label: 'role_broker'.tr,
        description: 'broker_desc'.tr,
        imagePath: 'assets/images/broker.png',
        selected: _selectedRole == 'broker',
        onTap: () => setState(() => _selectedRole = 'broker'),
      ),

      const SizedBox(height: 14),

      IllustrationRoleCard(
        label: 'role_customer'.tr,
        description: 'customer_desc'.tr,
        imagePath: 'assets/images/customer.png',
        selected: _selectedRole == 'customer',
        onTap: () => setState(() => _selectedRole = 'customer'),
      ),

      const SizedBox(height: 32),

      SiennaButton(
        label: 'continue_btn'.tr,
        onTap: _onContinue,
        icon: Icons.arrow_forward_rounded,
      ),

      const SizedBox(height: 20),

      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('already_account'.tr,
            style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text('log_in'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                  .copyWith(fontWeight: FontWeight.w700)),
        ),
      ]),

      const SizedBox(height: 8),
    ]);
  }

  // ── Gradient header (form step) ───────────────────────────────────────────

  Widget _buildGradientHeader() {
    final topPad = MediaQuery.of(context).padding.top;
    final totalHeight = topPad + 230.0;
    return FadeTransition(
      opacity: headerFade,
      child: ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          height: totalHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.darkBg, AppTheme.darkBg2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(children: [
            // Aurora orb accent
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HeaderOrbPainter(color: AppTheme.sienna),
                ),
              ),
            ),
            // Second orb (bottom-left)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _HeaderOrbPainter2(),
                ),
              ),
            ),
            // Content
            Positioned(
              top: topPad + 48,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shield_rounded, size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                      const Text('IBAL', style: TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Text('Create account',
                      style: AppTextStyle.h2(color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    'IBAL keeps your policy work in one place.',
                    style: AppTextStyle.bodySmall(color: Colors.white.withValues(alpha: 0.70)),
                  ),
                ],
              ),
            ),
            // Back button
            Positioned(
              top: topPad + 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _roleConfirmed = false;
                    _formController.reset();
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return FadeTransition(
      opacity: _formFade,
      child: SlideTransition(
        position: _formSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: 'personal_info'.tr),
            const SizedBox(height: 12),
            PremiumField(
                controller: _name,
                label: 'full_name'.tr,
                hint: 'full_name'.tr,
                prefixIcon: Icons.badge_outlined),
            const SizedBox(height: 10),
            PremiumField(
                controller: _email,
                label: 'email'.tr,
                hint: 'email'.tr,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            PremiumField(
              controller: _password,
              label: 'password'.tr,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 10),
            PremiumField(
              controller: _confirm,
              label: 'confirm_password'.tr,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscure: true,
            ),
            const SizedBox(height: 22),
            SectionTitle(title: 'location_contact'.tr),
            const SizedBox(height: 12),
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
            if (_selectedRole == 'broker') ...[
              const SizedBox(height: 22),
              SectionTitle(title: 'broker_company_info'.tr),
              const SizedBox(height: 12),
              PremiumField(
                  controller: _companyName,
                  label: 'company_name'.tr,
                  hint: 'company_name'.tr,
                  prefixIcon: Icons.business),
              const SizedBox(height: 10),
              PremiumField(
                  controller: _license,
                  label: 'license_number'.tr,
                  hint: 'license_number'.tr,
                  prefixIcon: Icons.verified_user_outlined),
              const SizedBox(height: 10),
              PremiumField(
                  controller: _tax,
                  label: 'tax_number'.tr,
                  hint: 'tax_number'.tr,
                  prefixIcon: Icons.receipt_long_outlined),
              const SizedBox(height: 10),
              PremiumField(
                  controller: _address,
                  label: 'company_address'.tr,
                  hint: 'company_address'.tr,
                  prefixIcon: Icons.location_on_outlined),
              const SizedBox(height: 10),
              PremiumField(
                  controller: _website,
                  label: 'website'.tr,
                  hint: 'https://...',
                  prefixIcon: Icons.language_outlined,
                  keyboardType: TextInputType.url),
              const SizedBox(height: 10),
              _UploadTile(
                label: 'Company Logo',
                value: _logo.text,
                icon: Icons.image_outlined,
                loading: _uploadingField == 'logo',
                onView: () => _openUploadedFile(_logo.text),
                onClear: () => setState(() => _logo.clear()),
                onTap: () => _uploadBrokerFile(
                  field: 'logo',
                  target: _logo,
                  endpoint: '/uploads/public/broker-logo',
                  accept: 'image/*',
                ),
              ),
              const SizedBox(height: 10),
              _UploadTile(
                label: 'ID Front',
                value: _idFront.text,
                icon: Icons.badge_outlined,
                loading: _uploadingField == 'idFront',
                onView: () => _openUploadedFile(_idFront.text),
                onClear: () => setState(() => _idFront.clear()),
                onTap: () => _uploadBrokerFile(
                  field: 'idFront',
                  target: _idFront,
                  endpoint: '/uploads/public/broker-document',
                  accept: 'image/*',
                ),
              ),
              const SizedBox(height: 10),
              _UploadTile(
                label: 'ID Back',
                value: _idBack.text,
                icon: Icons.badge_outlined,
                loading: _uploadingField == 'idBack',
                onView: () => _openUploadedFile(_idBack.text),
                onClear: () => setState(() => _idBack.clear()),
                onTap: () => _uploadBrokerFile(
                  field: 'idBack',
                  target: _idBack,
                  endpoint: '/uploads/public/broker-document',
                  accept: 'image/*',
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Terms row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: _acceptedTerms
                    ? AppTheme.siennaSoft
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    activeColor: AppTheme.sienna,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onChanged: (v) =>
                        setState(() => _acceptedTerms = v ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'I accept the Terms and Conditions and Privacy Policy.',
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.ink(context)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SiennaButton(
              label: 'create_account'.tr,
              loading: _loading,
              onTapAsync: _handleSignup,
              icon: Icons.person_add_outlined,
            ),
            const SizedBox(height: 20),
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('already_account'.tr,
                    style: AppTextStyle.bodySmall(
                        color: AppTheme.muted(context))),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: Text('log_in'.tr,
                      style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Wave clipper ──────────────────────────────────────────────────────────────

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height - 55);
    path.cubicTo(
      size.width * 0.20, size.height - 55,
      size.width * 0.35, size.height + 18,
      size.width * 0.60, size.height - 20,
    );
    path.cubicTo(
      size.width * 0.78, size.height - 48,
      size.width * 0.90, size.height - 30,
      size.width,        size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_) => false;
}

// ── Header orb painter ────────────────────────────────────────────────────────

class _HeaderOrbPainter extends CustomPainter {
  final Color color;
  const _HeaderOrbPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.85, size.height * 0.2),
      radius: size.width * 0.55,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HeaderOrbPainter o) => color != o.color;
}

class _HeaderOrbPainter2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.15, size.height * 0.85),
      radius: size.width * 0.40,
    );
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Upload tile ───────────────────────────────────────────────────────────────

class _UploadTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onClear;

  const _UploadTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.loading,
    required this.onTap,
    required this.onView,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = value.isNotEmpty;
    final dark     = AppTheme.isDark(context);

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: uploaded
                ? AppTheme.sienna.withValues(alpha: 0.60)
                : AppTheme.hairStrong(context),
            width: uploaded ? 1.5 : 1.0,
          ),
          boxShadow: uploaded
              ? [
                  BoxShadow(
                    color: AppTheme.sienna.withValues(alpha: 0.12),
                    blurRadius: 12,
                    spreadRadius: -3,
                  ),
                ]
              : [],
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: uploaded ? AppTheme.siennaSoft : AppTheme.surface2(context),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, size: 18,
                color: uploaded ? AppTheme.sienna : AppTheme.muted(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  uploaded ? 'Uploaded ✓' : 'Tap to upload',
                  style: AppTextStyle.eyebrow(
                      color: uploaded
                          ? AppTheme.sienna
                          : AppTheme.muted(context)),
                ),
              ],
            ),
          ),
          if (loading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppTheme.sienna),
            )
          else if (uploaded) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'View',
              onPressed: onView,
              icon: const Icon(Icons.visibility_outlined,
                  size: 18, color: AppTheme.sienna),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Replace',
              onPressed: onTap,
              icon: const Icon(Icons.sync_outlined,
                  size: 18, color: AppTheme.sienna),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Clear',
              onPressed: onClear,
              icon: Icon(Icons.close_rounded,
                  size: 18, color: AppTheme.muted(context)),
            ),
          ] else
            Icon(Icons.upload_file_outlined,
                size: 18, color: AppTheme.muted(context)),
        ]),
      ),
    );
  }
}
