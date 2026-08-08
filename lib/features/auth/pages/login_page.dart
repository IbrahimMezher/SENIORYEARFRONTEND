import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/controllers/language_controller.dart';
import 'package:fluttertest/core/utils/theme_controller.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/ibal_logo.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/features/auth/widgets/widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginService = LoginService();
  final _twoFaService = TwoFaService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _show2FA = false;
  String _pendingEmail = '';
  bool _pendingIsAdmin = false;
  String _pending2FAMethod = 'email';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) navigateAfterAuth(context);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: AppTextStyle.bodyMedium(color: Colors.white)),
        backgroundColor: AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ));

  Future<void> _handleLogin() async {
    if (_loading) return;
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('Please fill in all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      Map<String, dynamic> data = {};
      bool isAdmin = false;
      try {
        data = await _loginService.login(email: email, password: password);
      } on Exception catch (userErr) {
        final msg = userErr.toString().toLowerCase();
        if (msg.contains('not found') ||
            msg.contains('invalid') ||
            msg.contains('unauthorized') ||
            msg.contains('403') ||
            msg.contains('401') ||
            msg.contains('user')) {
          try {
            data = await _loginService.adminLogin(
                email: email, password: password);
            isAdmin = true;
          } catch (_) {
            rethrow;
          }
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      if (isAdmin) {
        final available = (data['availableTwoFaMethods'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['email'];
        String chosenMethod;
        if (available.length > 1) {
          final picked = await _showAdminMethodPicker();
          if (!mounted) return;
          if (picked == null) return;
          chosenMethod = picked;
        } else {
          chosenMethod = available.first;
        }
        await _twoFaService.sendAdmin2FACode(email, method: chosenMethod);
        setState(() {
          _pendingEmail = email;
          _pendingIsAdmin = true;
          _pending2FAMethod = chosenMethod;
          _show2FA = true;
        });
        return;
      }
      if (data['requiresTwoFa'] == true || data['twoFaEnabled'] == true) {
        String method = data['twoFaMethod']?.toString() ?? 'email';
        final available = (data['availableTwoFaMethods'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const ['email'];
        if (available.length > 1) {
          final chosen = await _showMethodPicker();
          if (!mounted) return;
          if (chosen == null) return;
          method = chosen;
        } else {
          method = available.first;
        }
        await _twoFaService.send2FACode(email, method: method);
        if (!mounted) return;
        setState(() {
          _pendingEmail = email;
          _pendingIsAdmin = false;
          _pending2FAMethod = method;
          _show2FA = true;
        });
      } else {
        await navigateAfterAuth(context);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _showMethodPicker() => showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _MethodPickerDialog(
          title: 'choose_verification_method'.tr,
          subtitle: 'How would you like to receive your login code?',
          ctx: ctx,
        ),
      );

  Future<String?> _showAdminMethodPicker() => showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _MethodPickerDialog(
          title: 'choose_2fa_method_title'.tr,
          subtitle:
              'Admin accounts require two-factor authentication on every sign-in.',
          ctx: ctx,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_show2FA) {
      return _TwoFAScreen(
        email: _pendingEmail,
        isAdmin: _pendingIsAdmin,
        method: _pending2FAMethod,
        twoFaService: _twoFaService,
        onVerified: () => navigateAfterAuth(context),
        onBack: () => setState(() {
          _show2FA = false;
          _pendingIsAdmin = false;
        }),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 52),

              // ── IBAL wordmark logo ───────────────────────────────────────
              const IbalLogo(width: 260),

              const SizedBox(height: 10),

              Text(
                'Insurance for what matters.',
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                    .copyWith(fontSize: 11),
              ),

              const SizedBox(height: 44),

              // ── Headline ───────────────────────────────────────────────────
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: [
                  TextSpan(
                    text: 'welcome_back'.tr,
                    style: AppTextStyle.h1(color: AppTheme.ink(context)),
                  ),
                  const TextSpan(
                    text: '.',
                    style: TextStyle(
                        color: AppTheme.sienna,
                        fontSize: 36,
                        fontWeight: FontWeight.w700),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Text(
                'continue_account'.tr,
                textAlign: TextAlign.center,
                style: AppTextStyle.bodyMedium(color: AppTheme.muted(context)),
              ),

              const SizedBox(height: 36),

              // ── Email field ────────────────────────────────────────────────
              PremiumField(
                label: 'email_address'.tr,
                hint: 'you@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),

              const SizedBox(height: 12),

              // ── Password field ─────────────────────────────────────────────
              PremiumField(
                label: 'password'.tr,
                hint: '••••••••',
                controller: _passCtrl,
                obscure: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),

              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/reset-password'),
                  child: Text('forgot_password'.tr,
                      style: AppTextStyle.bodySmall(color: AppTheme.sienna)),
                ),
              ),

              const SizedBox(height: 4),

              // ── CTA ────────────────────────────────────────────────────────
              SiennaButton(
                label: 'sign_in_btn'.tr,
                loading: _loading,
                onTapAsync: _handleLogin,
                icon: Icons.arrow_forward_outlined,
              ),

              const SizedBox(height: 32),

              // ── Utility controls ───────────────────────────────────────────
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                GetBuilder<ThemeController>(
                    builder: (tc) => _ControlPill(
                          icon: tc.isDarkMode
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          onTap: tc.toggleTheme,
                        )),
                const SizedBox(width: 10),
                GetBuilder<LanguageController>(
                    builder: (lc) => _ControlPill(
                          icon: Icons.language_outlined,
                          label: lc.isArabic ? 'EN' : 'AR',
                          onTap: () =>
                              lc.setLanguage(lc.isArabic ? 'en' : 'ar'),
                        )),
              ]),

              const SizedBox(height: 24),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Flexible(
                  child: Text('dont_have_account'.tr,
                      style: AppTextStyle.bodySmall(
                          color: AppTheme.muted(context))),
                ),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signup'),
                  child: Text('sign_up'.tr,
                      style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Field wrapper ─────────────────────────────────────────────────────────────

class _GlassField extends StatefulWidget {
  final String label;
  final Widget child;
  const _GlassField({required this.label, required this.child});
  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _focused
                ? AppTheme.sienna.withValues(alpha: 0.70)
                : AppTheme.hairStrong(context),
            width: _focused ? 1.5 : 1.0,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color:
                        AppTheme.sienna.withValues(alpha: dark ? 0.20 : 0.12),
                    blurRadius: 18,
                    spreadRadius: -4,
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                  start: 14, top: 10, bottom: 2),
              child: Text(
                widget.label,
                style: AppTextStyle.eyebrow(
                  color: _focused ? AppTheme.sienna : AppTheme.muted(context),
                ),
              ),
            ),
            widget.child,
          ],
        ),
      ),
    );
  }
}

// ── Utility pill button (theme / language) ────────────────────────────────────

class _ControlPill extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  const _ControlPill({required this.icon, required this.onTap, this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: label != null ? null : 36,
        padding:
            label != null ? const EdgeInsets.symmetric(horizontal: 14) : null,
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.hairStrong(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppTheme.muted(context)),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label!,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 2FA method picker dialog ──────────────────────────────────────────────────

class _MethodPickerDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final BuildContext ctx;
  const _MethodPickerDialog({
    required this.title,
    required this.subtitle,
    required this.ctx,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      title: Text(title, style: AppTextStyle.h3(color: AppTheme.ink(context))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(subtitle,
            style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        const SizedBox(height: 16),
        _MethodOption(
          icon: Icons.email_outlined,
          label: 'Email',
          subtitle: 'Send code to your email address',
          onTap: () => Navigator.pop(ctx, 'email'),
        ),
        const SizedBox(height: 8),
        _MethodOption(
          icon: Icons.sms_outlined,
          label: 'SMS',
          subtitle: 'Send code to your verified phone',
          onTap: () => Navigator.pop(ctx, 'sms'),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, null),
          child: Text('cancel'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        ),
      ],
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _MethodOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.hair(context)),
          ),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.siennaSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 18, color: AppTheme.sienna),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          AppTextStyle.bodySmall(color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style:
                          AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: AppTheme.muted(context)),
          ]),
        ),
      );
}

// ── 2FA Screen ────────────────────────────────────────────────────────────────

class _TwoFAScreen extends StatefulWidget {
  final String email;
  final bool isAdmin;
  final String method;
  final TwoFaService twoFaService;
  final VoidCallback onVerified;
  final VoidCallback onBack;
  const _TwoFAScreen({
    required this.email,
    required this.isAdmin,
    required this.method,
    required this.twoFaService,
    required this.onVerified,
    required this.onBack,
  });
  @override
  State<_TwoFAScreen> createState() => _TwoFAScreenState();
}

class _TwoFAScreenState extends State<_TwoFAScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  bool _resending = false;
  int _cooldown = 60;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _nodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _ctrls.map((c) => c.text).join();

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _cooldown--);
      return _cooldown > 0;
    });
  }

  void _onChanged(int i, String v) {
    if (v.length == 1 && i < 5) _nodes[i + 1].requestFocus();
    if (v.isEmpty && i > 0) _nodes[i - 1].requestFocus();
    if (i == 5 && v.length == 1) _verify();
    setState(() {});
  }

  Future<void> _resend() async {
    if (_resending) {
      _snack('OTP is already being sent.');
      return;
    }
    if (_cooldown > 0) {
      _snack('Please wait $_cooldown seconds before requesting another code.');
      return;
    }
    setState(() => _resending = true);
    try {
      _snack('Sending OTP...');
      if (widget.isAdmin) {
        await widget.twoFaService
            .sendAdmin2FACode(widget.email, method: widget.method);
      } else {
        await widget.twoFaService
            .send2FACode(widget.email, method: widget.method);
      }
      setState(() => _cooldown = 60);
      _startCooldown();
      _snack('Code resent!');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_code.length < 6) return;
    setState(() => _loading = true);
    try {
      if (widget.isAdmin) {
        await widget.twoFaService.verifyAdmin2FACode(
            email: widget.email, code: _code, method: widget.method);
      } else {
        await widget.twoFaService.verify2FACode(
            email: widget.email, code: _code, method: widget.method);
      }
      if (mounted) widget.onVerified();
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''));
        for (final c in _ctrls) {
          c.clear();
        }
        _nodes.first.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.screenPad,
            AppTheme.screenPad,
            AppTheme.screenPad,
            MediaQuery.of(context).viewInsets.bottom + AppTheme.screenPad,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.hair(context)),
                  ),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 15, color: AppTheme.ink(context)),
                ),
              ),

              const SizedBox(height: 40),

              // Shield icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(
                      color: AppTheme.sienna.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sienna.withValues(alpha: 0.20),
                      blurRadius: 20,
                      spreadRadius: -4,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_outlined,
                    color: AppTheme.sienna, size: 36),
              ),

              const SizedBox(height: 24),

              if (widget.isAdmin) ...[
                Text('security'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 8),
              ],
              Text('two_factor'.tr,
                  style: AppTextStyle.h2(color: AppTheme.ink(context))),
              const SizedBox(height: 8),
              Text(
                widget.isAdmin
                    ? 'Admin access requires 2FA verification on every sign-in.'
                    : (widget.method.toLowerCase() == 'sms'
                        ? 'Enter the 6-digit code sent to your phone'
                        : 'Enter the 6-digit code sent to ${widget.email}'),
                style: AppTextStyle.bodyMedium(color: AppTheme.muted(context)),
              ),

              const SizedBox(height: 40),

              // OTP boxes
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    6,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: OtpBox(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        onChanged: (v) => _onChanged(i, v),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SiennaButton(
                label: 'Verify',
                loading: _loading,
                onTap: _code.length == 6 ? _verify : null,
                icon: Icons.verified_outlined,
              ),

              const SizedBox(height: 20),

              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text("Didn't receive it?  ",
                      style: AppTextStyle.bodySmall(
                          color: AppTheme.muted(context))),
                  _cooldown > 0
                      ? Text('resend_in'.trParams({'seconds': '$_cooldown'}),
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.muted(context)))
                      : GestureDetector(
                          onTap: _resending ? null : _resend,
                          child: Text('resend'.tr,
                              style:
                                  AppTextStyle.bodySmall(color: AppTheme.sienna)
                                      .copyWith(fontWeight: FontWeight.w700)),
                        ),
                ]),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
            ],
          ),
        ),
      ),
    );
  }
}
