import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/auth/services/account_action_service.dart';

class AccountActionFlow {
  static final _service = AccountActionService();

  static Future<bool> run(BuildContext context, String action) async {
    final isDelete = action == 'DELETE';
    final title = isDelete ? 'delete_account'.tr : 'deactivate_account'.tr;
    final warning = isDelete
        ? 'delete_account_warning'.tr
        : 'deactivate_account_warning'.tr;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmStartDialog(
        title: title,
        warning: warning,
        isDelete: isDelete,
      ),
    );
    if (proceed != true || !context.mounted) return false;

    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EnterCodeDialog(isDelete: isDelete),
    );
    return done == true;
  }

  static Future<String> _request(String action) =>
      _service.requestActionCode(action);
  static Future<String> _confirm(String code) => _service.confirmAction(code);
}

class _ConfirmStartDialog extends StatefulWidget {
  final String title;
  final String warning;
  final bool isDelete;
  const _ConfirmStartDialog(
      {required this.title, required this.warning, required this.isDelete});
  @override
  State<_ConfirmStartDialog> createState() => _ConfirmStartDialogState();
}

class _ConfirmStartDialogState extends State<_ConfirmStartDialog> {
  bool _sending = false;

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await AccountActionFlow._request(widget.isDelete ? 'DELETE' : 'DEACTIVATE');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final danger =
        AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      title: Text(widget.title, style: AppTextStyle.h3(color: danger)),
      content: Text(widget.warning,
          style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: Text('cancel'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        ),
        TextButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sienna, strokeCap: StrokeCap.round))
              : Text('send_code'.tr,
                  style: AppTextStyle.button(color: danger)),
        ),
      ],
    );
  }
}

class _EnterCodeDialog extends StatefulWidget {
  final bool isDelete;
  const _EnterCodeDialog({required this.isDelete});
  @override
  State<_EnterCodeDialog> createState() => _EnterCodeDialogState();
}

class _EnterCodeDialogState extends State<_EnterCodeDialog> {
  final _codeCtrl = TextEditingController();
  bool _confirming = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_confirming) return;
    if (_codeCtrl.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('enter_6_digit_code'.tr),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _confirming = true);
    try {
      await AccountActionFlow._confirm(_codeCtrl.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final danger =
        AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius)),
      title: Text('enter_confirmation_code'.tr,
          style: AppTextStyle.h3(color: AppTheme.ink(context))),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('code_sent_to_email'.tr,
            style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        const SizedBox(height: 14),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTextStyle.h3(color: AppTheme.ink(context)),
          decoration: const InputDecoration(counterText: '', hintText: '••••••'),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: _confirming ? null : () => Navigator.pop(context, false),
          child: Text('cancel'.tr,
              style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
        ),
        TextButton(
          onPressed: _confirming ? null : _confirm,
          child: _confirming
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.sienna, strokeCap: StrokeCap.round))
              : Text('confirm'.tr, style: AppTextStyle.button(color: danger)),
        ),
      ],
    );
  }
}
