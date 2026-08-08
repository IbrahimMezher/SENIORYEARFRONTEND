import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/auth/services/auth_service.dart';
import 'package:fluttertest/features/auth/services/verify_service.dart';

class BrokerPendingPage extends StatefulWidget {
  const BrokerPendingPage({super.key});
  @override
  State<BrokerPendingPage> createState() => _BrokerPendingPageState();
}

class _BrokerPendingPageState extends State<BrokerPendingPage> {
  final _authService = LoginService();
  bool _checking = false;
  String _lastChecked = '';
  int _pollSeconds = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pollStatus();
  }

  Future<void> _pollStatus() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return;
      await _silentCheck();
    }
  }

  Future<void> _silentCheck() async {
    try {
      final status = await _authService.refreshStatus();
      if (!mounted) return;
      final now = TimeOfDay.now();
      setState(() => _lastChecked = 'Last checked: ${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}');
      if (status.toLowerCase() == 'active') {
        await navigateAfterAuth(context);
      }
    } catch (_) {}
  }

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      final status = await _authService.refreshStatus();
      if (!mounted) return;
      if (status.toLowerCase() == 'active') {
        await navigateAfterAuth(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('still_pending'.tr),
          backgroundColor: AppTheme.sienna, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _checking = false); }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('step_account_created'.tr, true),
      _Step('step_email_verified'.tr, true),
      _Step('step_waiting_admin'.tr, false, current: true),
      _Step('step_access_dashboard'.tr, false),
    ];
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: AuroraBackdrop(child: SafeArea(child: Padding(
        padding: const EdgeInsets.all(AppTheme.screenPad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 40),
          Container(width: 86, height: 86,
            decoration: BoxDecoration(color: AppTheme.siennaSoft, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppTheme.hair(context))),
            child: const Icon(Icons.shield_outlined, color: AppTheme.sienna, size: 42)),
          const SizedBox(height: 28),
          Text('broker_pending_heading'.tr, style: AppTextStyle.h2(color: AppTheme.ink(context)), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('broker_pending_sub'.tr, style: AppTextStyle.bodyMedium(color: AppTheme.muted(context)), textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ...steps.map((s) => Padding(padding: const EdgeInsets.only(bottom: 16), child: Row(children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(
              color: s.done ? (AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success)
                  : s.current ? AppTheme.sienna
                  : AppTheme.surface2(context),
              shape: BoxShape.circle,
              border: s.current ? Border.all(color: AppTheme.sienna, width: 2) : null,
            ), child: Icon(s.done ? Icons.check : s.current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                size: 14, color: (s.done || s.current) ? Colors.white : AppTheme.muted(context))),
            const SizedBox(width: 14),
            Text(s.label, style: AppTextStyle.bodySmall(color: s.done || s.current ? AppTheme.ink(context) : AppTheme.muted(context))
                .copyWith(fontWeight: s.current ? FontWeight.w600 : null)),
          ]))),
          const Spacer(),
          if (_lastChecked.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_lastChecked, style: AppTextStyle.bodySmall(color: AppTheme.muted(context)), textAlign: TextAlign.center),
            ),
          SiennaButton(label: _checking ? 'checking'.tr : 'check_status'.tr, loading: _checking, onTap: _checkStatus, icon: Icons.refresh),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text('back_to_login'.tr, style: AppTextStyle.bodySmall(color: AppTheme.muted(context)))),
        ]),
      ))),
    );
  }
}

class _Step { final String label; final bool done; final bool current;
  const _Step(this.label, this.done, {this.current = false}); }
