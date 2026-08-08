import 'package:flutter/material.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/gradient_button.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/customer/claims/services/claim_filing_service.dart';
import 'package:get/get.dart';

class ClaimsContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ClaimsContactBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.siennaBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.hair(context)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: AppTheme.sienna),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.sienna)),
        ]),
      ),
    );
  }
}

class FileClaimSheet extends StatefulWidget {
  final List<dynamic> transactions;
  final ClaimFilingService service;
  final VoidCallback onSuccess;

  const FileClaimSheet({
    super.key,
    required this.transactions,
    required this.service,
    required this.onSuccess,
  });

  @override
  State<FileClaimSheet> createState() => FileClaimSheetState();
}

class FileClaimSheetState extends State<FileClaimSheet> {
  int? _selectedTxnId;
  final _amount = TextEditingController();
  final _remarks = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amount.dispose();
    _remarks.dispose();
    super.dispose();
  }

  List<dynamic> get _eligibleTransactions => widget.transactions
      .where((t) =>
          (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED')
      .toList();

  DateTime? _claimsEligibleDate(Map<String, dynamic> t) {
    final raw = t['claimsEligibleDate']?.toString() ?? '';
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  bool _canFileClaim(Map<String, dynamic> t) {
    final eligDate = _claimsEligibleDate(t);
    if (eligDate == null) return false;
    return !DateTime.now().isBefore(eligDate);
  }

  int _daysUntilEligible(Map<String, dynamic> t) {
    final eligDate = _claimsEligibleDate(t);
    if (eligDate == null) return 0;
    final diff = eligDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _lockReason(Map<String, dynamic> t) {
    final eligDate = _claimsEligibleDate(t);
    if (eligDate == null) {
      final payment = (t['paymentStatus']?.toString().toUpperCase() ?? '');
      final delivery = (t['deliveryStatus']?.toString().toUpperCase() ?? '');
      if (payment != 'PAID') return 'Payment not confirmed yet';
      if (delivery == 'ACCEPTED_BY_BROKER' || delivery == 'SHIPPED') {
        return 'Delivery still in progress';
      }
      return 'Policy is not claim-eligible yet';
    }
    return 'Claims eligible from ${_fmt(eligDate)}';
  }

  Map<String, dynamic>? get _selectedTx {
    if (_selectedTxnId == null) return null;
    final idx = _eligibleTransactions.indexWhere((t) {
      final id = t['transactionId'];
      return (id is int ? id : int.tryParse(id.toString()) ?? 0) ==
          _selectedTxnId;
    });
    return idx == -1
        ? null
        : _eligibleTransactions[idx] as Map<String, dynamic>;
  }

  bool get _selectedCanFile =>
      _selectedTx != null && _canFileClaim(_selectedTx!);

  Future<void> _submit() async {
    if (_selectedTxnId == null) {
      _snack('Select a transaction');
      return;
    }
    if (!_selectedCanFile) {
      final tx = _selectedTx!;
      final d = _daysUntilEligible(tx);
      _snack(
          'Waiting period active — claims eligible in $d day${d == 1 ? '' : 's'}');
      return;
    }
    if (_amount.text.isEmpty) {
      _snack('Enter claim amount');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.service.fileClaim(
        transactionId: _selectedTxnId!,
        claimAmount: double.tryParse(_amount.text) ?? 0,
        remarks: _remarks.text,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final eligible = _eligibleTransactions;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                      color: AppTheme.sienna,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text('file_claim'.tr,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
            ]),
            const SizedBox(height: 20),
            if (eligible.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkDanger.withValues(alpha: 0.12)
                        : AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(Icons.block_outlined,
                      size: 18,
                      color: AppTheme.isDark(context)
                          ? AppTheme.darkDanger
                          : AppTheme.danger),
                  const SizedBox(width: 10),
                  Flexible(
                      child: Text(
                    'No accepted policies found. Claims can only be filed after your broker has approved your policy.',
                    style: AppTextStyle.bodySmall(
                        color: AppTheme.isDark(context)
                            ? AppTheme.darkDanger
                            : AppTheme.danger),
                  )),
                ]),
              ),
              const SizedBox(height: 16),
              return_,
            ],
            Text('select_transaction'.tr,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.54))),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.hair(context))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedTxnId,
                  hint: Text('choose_transaction'.tr,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                          fontSize: 13)),
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.sienna),
                  items: eligible.map((t) {
                    final id = t['transactionId'] is int
                        ? t['transactionId'] as int
                        : int.tryParse(t['transactionId'].toString()) ?? 0;
                    final name = t['policy']?['policyName']?.toString() ??
                        'Transaction #$id';
                    final canFile = _canFileClaim(t as Map<String, dynamic>);
                    return DropdownMenuItem<int>(
                      enabled: canFile,
                      value: id,
                      child: Row(children: [
                        Expanded(
                            child: Text(name,
                                style: AppTextStyle.bodyMedium(
                                    color: canFile
                                        ? AppTheme.ink(context)
                                        : AppTheme.muted(context)),
                                overflow: TextOverflow.ellipsis)),
                        if (!canFile) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.lock_clock_outlined,
                              size: 14,
                              color: AppTheme.isDark(context)
                                  ? AppTheme.darkWarning
                                  : AppTheme.warning),
                        ],
                      ]),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedTxnId = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (eligible
                    .any((t) => !_canFileClaim(t as Map<String, dynamic>)) &&
                _selectedTx == null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.25))),
                child: Row(children: [
                  Icon(Icons.lock_clock_outlined,
                      size: 14, color: AppTheme.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Locked policies are not ready for claims yet.',
                      style: AppTextStyle.eyebrow(color: AppTheme.warning),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedTx != null && !_selectedCanFile) ...[
              _WaitingBanner(
                eligibleDate: _claimsEligibleDate(_selectedTx!),
                daysLeft: _daysUntilEligible(_selectedTx!),
                message: _lockReason(_selectedTx!),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedTx != null && _selectedCanFile) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkSuccess.withValues(alpha: 0.12)
                        : AppTheme.successBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: (AppTheme.isDark(context)
                                ? AppTheme.darkSuccess
                                : AppTheme.success)
                            .withValues(alpha: 0.3))),
                child: Row(children: [
                  Icon(Icons.check_circle_outline,
                      size: 14,
                      color: AppTheme.isDark(context)
                          ? AppTheme.darkSuccess
                          : AppTheme.success),
                  const SizedBox(width: 8),
                  Text('eligible_claims'.tr,
                      style: AppTextStyle.eyebrow(
                          color: AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success)),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            PremiumField(
              label: 'claim_amount'.tr,
              hint: '0.00',
              controller: _amount,
              keyboardType: TextInputType.number,
              enabled: _selectedCanFile,
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 16),
            PremiumField(
              label: 'remarks'.tr,
              hint: 'Describe your claim...',
              controller: _remarks,
              maxLines: 3,
              enabled: _selectedCanFile,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Submit Claim',
              loading: _loading,
              onTap: _selectedCanFile ? _submit : null,
              icon: Icons.assignment_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget get return_ => const SizedBox.shrink();
}

class _WaitingBanner extends StatelessWidget {
  final DateTime? eligibleDate;
  final int daysLeft;
  final String message;
  const _WaitingBanner({
    required this.eligibleDate,
    required this.daysLeft,
    required this.message,
  });

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final warningColor =
        AppTheme.isDark(context) ? AppTheme.darkWarning : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: warningColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: warningColor.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.lock_clock_outlined, size: 16, color: warningColor),
          const SizedBox(width: 8),
          Text('waiting_period_active'.tr,
              style: AppTextStyle.bodySmall(color: warningColor)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text(
          eligibleDate == null
              ? message
              : '$message '
                  '($daysLeft day${daysLeft == 1 ? '' : 's'} remaining).',
          style:
              AppTextStyle.eyebrow(color: warningColor).copyWith(height: 1.5),
        ),
      ]),
    );
  }
}
