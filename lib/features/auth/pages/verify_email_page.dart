import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/features/auth/widgets/widgets.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});
  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _authService = OtpService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  late TextEditingController _emailCtrl;

  bool _editingEmail = false;
  bool _updatingEmail = false;
  String _email = '';
  bool _sendingOtp = false;
  bool _verifying = false;
  bool _otpSent = false;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController();
    _loadEmail();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEmail() async {
    String e = '';
    try {
      e = await SecureStorageService.getEmail() ?? '';
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _email = e;
      _emailCtrl.text = e;
    });
    try {
      await _sendOtp();
    } catch (_) {}
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _snack(String msg, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppTheme.danger : AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28)),
      ));

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (index == 5 && value.length == 1) _verify();
    setState(() {});
  }

  Future<void> _updateEmail() async {
    if (_updatingEmail) return;
    final newEmail = _emailCtrl.text.trim();
    if (newEmail.isEmpty || newEmail == _email) {
      setState(() => _editingEmail = false);
      return;
    }
    setState(() => _updatingEmail = true);
    try {
      await _authService.changeEmail(newEmail);
      if (!mounted) return;

      setState(() {
        _email = newEmail;
        _editingEmail = false;
        _otpSent = false;
        _resendCooldown = 0;
        _updatingEmail = false;
        for (final c in _controllers) c.clear();
      });
      _snack('Email updated! Sending new OTP...');

      await Future.delayed(const Duration(milliseconds: 100));
      await _sendOtp();
    } catch (e) {
      if (mounted) {
        setState(() => _updatingEmail = false);
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    }
  }

  Future<void> _sendOtp() async {
    if (_sendingOtp) {
      _snack('OTP is already being sent.');
      return;
    }
    if (_resendCooldown > 0) {
      _snack('Please wait $_resendCooldown seconds before requesting another code.');
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      await _authService.sendOtp();
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _resendCooldown = 60;
      });
      _startCooldown();
      _snack('OTP sent to $_email');
    } catch (e) {
      if (mounted)
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _verify() async {
    if (_verifying) return;
    if (_otp.length < 6) {
      _snack('Enter the 6-digit code', error: true);
      return;
    }
    setState(() => _verifying = true);
    try {
      await _authService.verifyEmailOtp(_otp);
      if (!mounted) return;
      await SecureStorageService.write('emailVerified', 'true');
      final role = await SecureStorageService.getRole() ?? '';
      if (mounted) {
        if (role.toLowerCase() == 'broker') {
          await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radius)),
                    title: Row(children: [
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: AppTheme.accentSoft(context),
                              borderRadius:
                                  BorderRadius.circular(28)),
                          child: const Icon(Icons.hourglass_empty,
                              color: AppTheme.sienna, size: 16)),
                      const SizedBox(width: 10),
                      Text('pending_approval'.tr, style: AppTextStyle.h3()),
                    ]),
                    content: Text(
                      'Your email has been verified!\n\nYour broker account is now under review. Our admin team will approve your application shortly.\n\nYou will receive an email once a decision has been made.',
                      style: AppTextStyle.bodySmall(),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await SecureStorageService.clearSession();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text('back_to_login'.tr,
                            style:
                                AppTextStyle.bodySmall(color: AppTheme.sienna)
                                    .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ));
        } else {
          await SecureStorageService.clearSession();
          _snack('Email verified. Please log in.');
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''), error: true);
        for (final c in _controllers) c.clear();
        _focusNodes.first.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: AuroraBackdrop(
        orbAlignment: const Alignment(-0.6, -0.7),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.screenPad, vertical: 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              GestureDetector(
                onTap: () => Navigator.pop(context),
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
              const SizedBox(height: 32),

              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.accentSoft(context),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: AppTheme.sienna, size: 32),
              ),
              const SizedBox(height: 20),

              Text('verify_email_title'.tr,
                  style: AppTextStyle.h2(color: AppTheme.ink(context))),
              const SizedBox(height: 8),
              Text('enter_6digit'.tr,
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              const SizedBox(height: 4),

              if (!_editingEmail)
                Row(children: [
                  Expanded(
                      child: Text(
                    _email,
                    style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                        .copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() {
                      _editingEmail = true;
                      _emailCtrl.text = _email;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppTheme.accentSoft(context),
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('update'.tr,
                          style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                    ),
                  ),
                ])
              else
                Row(children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.isDark(context)
                            ? AppTheme.darkSurface
                            : AppTheme.lightSurface2,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: AppTheme.sienna.withValues(alpha: 0.5)),
                      ),
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.ink(context)),
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _updatingEmail
                      ? const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                              color: AppTheme.sienna, strokeWidth: 2))
                      : GestureDetector(
                          onTap: _updateEmail,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                                color: AppTheme.sienna,
                                borderRadius: BorderRadius.circular(999)),
                            child: Text('save'.tr,
                                style: AppTextStyle.button(
                                    color: AppTheme.siennaFg)),
                          ),
                        ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _editingEmail = false),
                    child: Icon(Icons.close,
                        size: 18, color: AppTheme.muted(context)),
                  ),
                ]),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                    6,
                    (i) => SizedBox(
                          width: (MediaQuery.of(context).size.width -
                                  AppTheme.screenPad * 2 -
                                  40) /
                              6,
                          child: OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigitChanged(i, v),
                          ),
                        )),
              ),
              const SizedBox(height: 28),

              SiennaButton(
                label: 'verify_btn'.tr,
                loading: _verifying,
                onTap: _otp.length == 6 ? _verify : null,
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 20),

              if (!_otpSent)
                SiennaButton(
                  label: 'send_otp_btn'.tr,
                  loading: _sendingOtp,
                  onTap: _sendOtp,
                  ghost: true,
                  icon: Icons.send_outlined,
                )
              else
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('didnt_receive'.tr,
                      style: AppTextStyle.bodySmall(
                          color: AppTheme.muted(context))),
                  GestureDetector(
                    onTap: _resendCooldown > 0 ? null : _sendOtp,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'resend_code'.tr,
                      style: AppTextStyle.bodySmall(
                        color: _resendCooldown > 0
                            ? AppTheme.muted(context)
                            : AppTheme.sienna,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ]),
            ]),
          ),
        ),
      ),
    );
  }
}
