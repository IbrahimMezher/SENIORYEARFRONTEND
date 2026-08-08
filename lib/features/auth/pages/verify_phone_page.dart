import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/verify_service.dart';
import 'package:fluttertest/features/auth/widgets/widgets.dart';

class VerifyPhonePage extends StatefulWidget {
  const VerifyPhonePage({super.key});

  @override
  State<VerifyPhonePage> createState() => _VerifyPhonePageState();
}

class _VerifyPhonePageState extends State<VerifyPhonePage>
    with TickerProviderStateMixin {
  final _api = ApiService();

  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _otpSent = false;
  bool _loading = false;

  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _pulseController;
  late AnimationController _stepController;
  late AnimationController _shakeController;
  late AnimationController _successController;

  late Animation<double> _headerFade;
  late Animation<double> _headerScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _pulse;
  late Animation<double> _stepFade;
  late Animation<Offset> _stepSlide;
  late Animation<double> _shake;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _headerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut));
    _headerScale = Tween<double>(begin: 1.05, end: 1.0).animate(
        CurvedAnimation(parent: _headerController, curve: Curves.easeOut));

    _contentController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _contentController, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _contentController, curve: Curves.easeOutCubic));

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.95, end: 1.05).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _stepController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _stepFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _stepController, curve: Curves.easeOut));
    _stepSlide = Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _stepController, curve: Curves.easeOutCubic));

    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shake = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    _successController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        _contentController.forward();
        _stepController.forward();
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    _stepController.dispose();
    _shakeController.dispose();
    _successController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _normalizePhone(String input) {
    final s = (input ?? '').trim();
    if (s.isEmpty) return '';
    if (s.startsWith('+')) {
      // keep leading + and strip other non-digits
      final digits = s.replaceAll(RegExp(r'[^\d+]'), '');
      return digits;
    }
    var digits = s.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '+961$digits';
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
    if (index == 5 && value.length == 1) _verifyOtp();
    setState(() {});
  }

  Future<void> _sendOtp() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      final fullPhone = _normalizePhone(phone);
      final r =
          await _api.post('/auth/send-phone-otp', {'phoneNumber': fullPhone});
      if (r.statusCode == 200) {
        await _stepController.reverse();
        setState(() => _otpSent = true);
        _stepController.forward();
        _snack('OTP sent! 📱');
      } else {
        _snack('Failed to send OTP');
      }
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_loading) return;
    if (_otp.length < 6) {
      _snack('Please enter the full 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      final fullPhone = _normalizePhone(phone);
      final r = await _api.post(
          '/auth/verify-phone-otp', {'phoneNumber': fullPhone, 'code': _otp});
      if (r.statusCode == 200) {
        await _successController.forward();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await SecureStorageService.write('phoneVerified', 'true');
          await refreshStoredAuthStatus();
          if (mounted) await navigateAfterAuth(context);
        }
      } else {
        _shakeController.forward(from: 0);
        for (final c in _otpControllers) c.clear();
        _focusNodes.first.requestFocus();
        _snack('Invalid OTP code. Try again!');
      }
    } catch (e) {
      _shakeController.forward(from: 0);
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: Column(
        children: [
          FadeTransition(
            opacity: _headerFade,
            child: ScaleTransition(
              scale: _headerScale,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Container(
                  height: 230,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.siennaSoft,
                    border: Border(
                        bottom: BorderSide(color: AppTheme.hair(context))),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 44,
                        left: 16,
                        child: GestureDetector(
                          onTap: () {
                            if (_otpSent) {
                              _stepController.reverse().then((_) {
                                setState(() {
                                  _otpSent = false;
                                  for (final c in _otpControllers) c.clear();
                                });
                                _stepController.forward();
                              });
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: AppTheme.surface2(context),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.2))),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                size: 16, color: AppTheme.sienna),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 52,
                        right: 16,
                        child: Row(children: [
                          _StepDot(active: !_otpSent),
                          const SizedBox(width: 4),
                          _StepDot(active: _otpSent)
                        ]),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 60,
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: _otpSent
                                ? Container(
                                    key: const ValueKey('otp'),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                        color: AppTheme.surface2(context),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppTheme.hair(context),
                                            width: 2)),
                                    child: const Icon(Icons.sms_outlined,
                                        size: 30, color: AppTheme.sienna))
                                : Container(
                                    key: const ValueKey('phone'),
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                        color: AppTheme.surface2(context),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppTheme.hair(context),
                                            width: 2)),
                                    child: const Icon(
                                        Icons.phone_android_rounded,
                                        size: 30,
                                        color: AppTheme.sienna)),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        right: 24,
                        child: Column(children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                                _otpSent
                                    ? 'Enter Your Code'
                                    : 'Phone Verification',
                                key: ValueKey('title$_otpSent'),
                                style: AppTextStyle.h3(color: AppTheme.sienna)),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _otpSent
                                  ? 'Enter the 6-digit code sent to your phone'
                                  : 'Enter your number to receive an OTP',
                              key: ValueKey('sub$_otpSent'),
                              style: AppTextStyle.eyebrow(
                                  color: AppTheme.muted(context)),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                  child: FadeTransition(
                    opacity: _stepFade,
                    child: SlideTransition(
                      position: _stepSlide,
                      child: _otpSent ? _buildOtpStep() : _buildPhoneStep(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.siennaSoft,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppTheme.sienna.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child:
            Icon(Icons.phone_android_rounded, size: 24, color: AppTheme.sienna),
      ),
      const SizedBox(height: 18),
      Text('your_phone_number'.tr,
          style: AppTextStyle.h3(color: AppTheme.ink(context))),
      const SizedBox(height: 6),
      Text("We'll send a one-time code to verify your number",
          style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
      const SizedBox(height: 28),
      Container(
        decoration: BoxDecoration(
            color: AppTheme.isDark(context)
                ? AppTheme.darkSurface
                : AppTheme.lightSurface2,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.hair(context))),
        child: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: AppTextStyle.bodySmall(color: AppTheme.ink(context)),
          decoration: InputDecoration(
            hintText: '70 123 456',
            hintStyle: AppTextStyle.bodySmall(
                color: AppTheme.muted(context).withValues(alpha: 0.6)),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🇱🇧', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('+961',
                    style: AppTextStyle.bodySmall(color: AppTheme.sienna)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 6),
                Container(width: 1, height: 20, color: AppTheme.hair(context)),
              ]),
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
      const SizedBox(height: 28),
      SiennaButton(
          label: 'send_otp_btn'.tr, loading: _loading, onTap: _sendOtp),
      const SizedBox(height: 20),
      Center(
        child: TextButton(
          onPressed: () async {
            await SecureStorageService.write('phoneVerified', 'false');
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              await navigateAfterAuth(context);
            }
          },
          child: Text('skip_for_now'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        ),
      ),
    ]);
  }

  Widget _buildOtpStep() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
            color: AppTheme.siennaSoft,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.sienna.withValues(alpha: 0.3), width: 1.5)),
        child: Icon(Icons.sms_outlined, size: 24, color: AppTheme.sienna),
      ),
      const SizedBox(height: 18),
      Text('enter_otp'.tr,
          style: AppTextStyle.h3(color: AppTheme.ink(context))),
      const SizedBox(height: 6),
      RichText(
        text: TextSpan(
          style: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
          children: [
            const TextSpan(text: 'Code sent to '),
            TextSpan(
                text: _normalizePhone(_phoneController.text),
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
      const SizedBox(height: 32),
      AnimatedBuilder(
        animation: _shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(
              _shake.value > 0
                  ? 8 * ((_shake.value * 10).round() % 2 == 0 ? 1 : -1)
                  : 0,
              0),
          child: child,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
              6,
              (i) => OtpBox(
                    controller: _otpControllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (v) => _onDigitChanged(i, v),
                  )),
        ),
      ),
      const SizedBox(height: 32),
      SiennaButton(
          label: 'Verify OTP',
          loading: _loading,
          onTap: _otp.length == 6 ? _verifyOtp : null),
      const SizedBox(height: 20),
      Center(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('didnt_receive'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          GestureDetector(
            onTap: () {
              _stepController.reverse().then((_) {
                setState(() {
                  _otpSent = false;
                  for (final c in _otpControllers) c.clear();
                });
                _stepController.forward();
              });
            },
            child: Text('resend'.tr,
                style: AppTextStyle.button(color: AppTheme.sienna)),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: () async {
            await SecureStorageService.write('phoneVerified', 'false');
            if (!mounted) return;
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              await navigateAfterAuth(context);
            }
          },
          child: Text('skip_for_now'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        ),
      ),
    ]);
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 20 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
