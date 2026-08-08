import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _authService = PasswordService();

  final _email = TextEditingController();
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();

  int _step = 0;
  bool _loading = false;

  late final AnimationController _stepCtrl;
  late final Animation<double> _stepFade;
  late final Animation<Offset> _stepSlide;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _stepFade = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _stepSlide = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic)
        .drive(Tween(begin: const Offset(0.06, 0), end: Offset.zero));
    _stepCtrl.forward();
  }

  @override
  void dispose() {
    _stepCtrl.dispose();
    _email.dispose();
    _token.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: AppTextStyle.bodySmall(color: Colors.white)),
        backgroundColor: error ? AppTheme.danger : AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
      ));

  Future<void> _animateToStep(int step) async {
    await _stepCtrl.reverse();
    setState(() => _step = step);
    _stepCtrl.forward();
  }

  Future<void> _requestReset() async {
    if (_loading) return;
    if (_email.text.trim().isEmpty) {
      _snack('Please enter your email', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.forgotPassword(_email.text.trim().toLowerCase());
      if (!mounted) return;
      await _animateToStep(1);
      _snack('Reset token sent — check your email');
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReset() async {
    if (_loading) return;
    if (_token.text.trim().isEmpty) {
      _snack('Please enter the token from your email', error: true);
      return;
    }
    if (_newPassword.text.isEmpty) {
      _snack('Please enter a new password', error: true);
      return;
    }
    if (_newPassword.text != _confirm.text) {
      _snack('Passwords do not match', error: true);
      return;
    }
    if (_newPassword.text.length < 6) {
      _snack('Password must be at least 6 characters', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _authService.resetPassword(
        token: _token.text.trim(),
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      _snack('Password reset successfully!');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: AuroraBackdrop(
        orbAlignment: const Alignment(-0.7, -0.5),
        child: SafeArea(
          child: Column(children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPad, 16, AppTheme.screenPad, 0),
              child: Row(children: [

                GestureDetector(
                  onTap: () {
                    if (_step == 1) {
                      _animateToStep(0);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.surface(context),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppTheme.hair(context)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15, color: AppTheme.ink(context)),
                  ),
                ),
                const Spacer(),

                Row(mainAxisSize: MainAxisSize.min, children: [
                  _StepDot(active: _step == 0),
                  const SizedBox(width: 4),
                  _StepDot(active: _step == 1),
                ]),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.screenPad, 36, AppTheme.screenPad, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.siennaSoft,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.hair(context)),
                      ),
                      child: Icon(
                        _step == 0
                            ? Icons.lock_reset_outlined
                            : Icons.mark_email_read_outlined,
                        color: AppTheme.sienna,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('account_security'.tr,
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                    const SizedBox(height: 6),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Align(
                        key: ValueKey(_step),
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _step == 0
                              ? 'reset_password'.tr
                              : 'enter_reset_token_title'.tr,
                          style: AppTextStyle.h2(color: AppTheme.ink(context)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        key: ValueKey('sub$_step'),
                        _step == 0
                            ? 'reset_password_sub'.tr
                            : 'We sent a token to ${_email.text}. Paste it below.',
                        style: AppTextStyle.bodySmall(
                                color: AppTheme.muted(context))
                            .copyWith(height: 1.5),
                      ),
                    ),
                  ]),
            ),

            const SizedBox(height: 32),

            Expanded(
              child: FadeTransition(
                opacity: _stepFade,
                child: SlideTransition(
                  position: _stepSlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppTheme.screenPad, 0, AppTheme.screenPad, 40),
                    child: _step == 0 ? _buildStep1() : _buildStep2(),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PremiumField(
        label: 'email_address'.tr,
        hint: 'you@example.com',
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.mail_outline_rounded,
      ),
      const SizedBox(height: 24),
      SiennaButton(
        label: 'send_reset_token'.tr,
        loading: _loading,
        onTap: _requestReset,
        icon: Icons.send_outlined,
      ),
      const SizedBox(height: 20),
      Center(
        child: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          child: Text('back_to_login'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  Widget _buildStep2() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      PremiumField(
        label: 'reset_token'.tr,
        hint: 'paste_token'.tr,
        controller: _token,
        prefixIcon: Icons.vpn_key_outlined,
      ),
      const SizedBox(height: 20),

      PremiumField(
        label: 'new_password'.tr,
        hint: '••••••••',
        controller: _newPassword,
        prefixIcon: Icons.lock_outline_rounded,
        obscure: true,
      ),
      const SizedBox(height: 12),

      PremiumField(
        label: 'confirm_new_password'.tr,
        hint: '••••••••',
        controller: _confirm,
        prefixIcon: Icons.lock_outline_rounded,
        obscure: true,
      ),
      const SizedBox(height: 24),

      SiennaButton(
        label: 'reset_password_btn'.tr,
        loading: _loading,
        onTap: _confirmReset,
        icon: Icons.check_outlined,
      ),
      const SizedBox(height: 20),

      Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text("Didn't get the email?  ",
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          GestureDetector(
            onTap: _loading ? null : _requestReset,
            child: Text('resend'.tr,
                style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ]);
  }
}


class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: active ? 20 : 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? AppTheme.sienna : AppTheme.hair(context),
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
