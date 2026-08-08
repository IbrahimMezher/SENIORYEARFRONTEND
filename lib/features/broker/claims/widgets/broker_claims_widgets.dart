import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class BrokerClaimCard extends StatelessWidget {
  final dynamic claim;
  final bool isDark;
  final Color primary;
  final Future<void> Function(int, String) onUpdateStatus;

  const BrokerClaimCard({
    super.key,
    required this.claim,
    required this.isDark,
    required this.primary,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final c = claim as Map<String, dynamic>;
    final claimId = _toInt(c['claimId']);
    final status = c['claimStatus']?.toString() ?? 'Pending';
    final amount = c['claimAmount']?.toString() ?? '0';
    final remarks = c['remarks']?.toString() ?? '';
    final policyName =
        c['transaction']?['policy']?['policyName']?.toString() ?? '—';
    final userName = c['transaction']?['user']?['fullName']?.toString() ?? '—';
    final userPhone =
        c['transaction']?['user']?['phoneNumber']?.toString() ?? '';
    final userEmail = c['transaction']?['user']?['email']?.toString() ?? '';
    final date = c['claimDate']?.toString().split('T').first ?? '';

    return PremiumCard(
      onTap: () => _showDetail(context, c),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(policyName,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(userName, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(20)),
            child: Text('\$$amount',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
        if (remarks.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(remarks,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ],
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          BrokerStatusBadge(status: status),
          Row(children: [
            Text(date, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
          ]),
        ]),
        if (status.toUpperCase() == 'PENDING') ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.hair(context)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => onUpdateStatus(claimId, 'Rejected'),
              child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: Center(
                      child: Text('reject'.tr,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.danger)))),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: GestureDetector(
              onTap: () => onUpdateStatus(claimId, 'Approved'),
              child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3))),
                  child: Center(
                      child: Text('approve'.tr,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success)))),
            )),
          ]),
        ],
        if (userPhone.isNotEmpty || userEmail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (userPhone.isNotEmpty)
              BrokerSmallContactBtn(
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: () => _launch('tel:$userPhone')),
            if (userPhone.isNotEmpty && userEmail.isNotEmpty)
              const SizedBox(width: 8),
            if (userEmail.isNotEmpty)
              BrokerSmallContactBtn(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () => _launch('mailto:$userEmail')),
          ]),
        ],
      ]),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> c) {
    final status = c['claimStatus']?.toString() ?? 'Pending';
    final userName = c['transaction']?['user']?['fullName']?.toString() ?? '—';
    final userEmail = c['transaction']?['user']?['email']?.toString() ?? '';
    final userPhone =
        c['transaction']?['user']?['phoneNumber']?.toString() ?? '';
    final policyName =
        c['transaction']?['policy']?['policyName']?.toString() ?? '—';
    final catName =
        c['transaction']?['policy']?['category']?['categoryName']?.toString() ??
            '—';
    final tierName =
        c['transaction']?['coverageTier']?['tierName']?.toString() ?? '—';
    final claimId = _toInt(c['claimId']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppTheme.hair(context),
                          borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Expanded(
                    child: Text(
                        'claim_number'.trParams({'id': '${c['claimId']}'}),
                        style: AppTextStyle.h3(color: AppTheme.ink(context)))),
                BrokerStatusBadge(status: status),
              ]),
              const SizedBox(height: 20),
              BrokerInfoSection('Policy',
                  {'Name': policyName, 'Category': catName, 'Tier': tierName}),
              BrokerInfoSection('Customer', {
                'Name': userName,
                if (userEmail.isNotEmpty) 'Email': userEmail,
                if (userPhone.isNotEmpty) 'Phone': userPhone,
              }),
              BrokerInfoSection('Claim', {
                'Amount': '\$${c['claimAmount'] ?? '0'}',
                'Date': c['claimDate']?.toString().split('T').first ?? '—',
                'Remarks': c['remarks']?.toString() ?? '—',
              }),
              if (status.toUpperCase() == 'PENDING') ...[
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onUpdateStatus(claimId, 'Rejected');
                    },
                    child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppTheme.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.3))),
                        child: Center(
                            child: Text('reject'.tr,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.danger)))),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onUpdateStatus(claimId, 'Approved');
                    },
                    child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                            color: AppTheme.successBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    AppTheme.success.withValues(alpha: 0.3))),
                        child: Center(
                            child: Text('approve'.tr,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success)))),
                  )),
                ]),
              ],
              if (userPhone.isNotEmpty || userEmail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (userPhone.isNotEmpty)
                    Expanded(
                        child: BrokerBigContactBtn(
                            icon: Icons.phone,
                            label: 'Call',
                            onTap: () => _launch('tel:$userPhone'))),
                  if (userPhone.isNotEmpty && userEmail.isNotEmpty)
                    const SizedBox(width: 10),
                  if (userEmail.isNotEmpty)
                    Expanded(
                        child: BrokerBigContactBtn(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            onTap: () => _launch('mailto:$userEmail'))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }
}

class BrokerTxCard extends StatelessWidget {
  final dynamic tx;
  final bool isDark;
  final Color primary;
  final Future<void> Function(int) onApprove;
  final Future<void> Function(int) onReject;

  const BrokerTxCard({
    super.key,
    required this.tx,
    required this.isDark,
    required this.primary,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final t = tx as Map<String, dynamic>;
    final txId = _toInt(t['transactionId']);
    final brokerStatus = t['brokerStatus']?.toString() ?? 'PENDING';
    final amount = t['amountPaid']?.toString() ?? '0';
    final policyName = t['policy']?['policyName']?.toString() ?? '—';
    final tierName = t['coverageTier']?['tierName']?.toString() ?? '—';
    final userName = t['user']?['fullName']?.toString() ?? '—';
    final userEmail = t['user']?['email']?.toString() ?? '';
    final userPhone = t['user']?['phoneNumber']?.toString() ?? '';
    final date = t['purchaseDate']?.toString().split('T').first ?? '';
    final policyDuration =
        t['policy']?['policyDuration']?['label']?.toString() ?? '—';
    final waitingDays = t['policy']?['waitingPeriodDays']?.toString() ?? '0';
    final isPending = brokerStatus.toUpperCase() == 'PENDING';

    return PremiumCard(
      onTap: () => _showDetail(context, t, txId, brokerStatus),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(policyName,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$userName  •  $tierName', style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(20)),
            child: Text('\$$amount',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          BrokerStatusBadge(status: brokerStatus),
          Row(children: [
            Text(date, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4)),
          ]),
        ]),
        if (isPending) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.hair(context)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: () => onReject(txId),
              child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.dangerBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.danger.withValues(alpha: 0.3))),
                  child: Center(
                      child: Text('reject'.tr,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.danger)))),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: GestureDetector(
              onTap: () => onApprove(txId),
              child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.3))),
                  child: Center(
                      child: Text('accept'.tr,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.success)))),
            )),
          ]),
        ],
        if (userPhone.isNotEmpty || userEmail.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (userPhone.isNotEmpty)
              BrokerSmallContactBtn(
                  icon: Icons.phone,
                  label: 'Call',
                  onTap: () => _launch('tel:$userPhone')),
            if (userPhone.isNotEmpty && userEmail.isNotEmpty)
              const SizedBox(width: 8),
            if (userEmail.isNotEmpty)
              BrokerSmallContactBtn(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () => _launch('mailto:$userEmail')),
          ]),
        ],
      ]),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> t, int txId,
      String brokerStatus) {
    final userName = t['user']?['fullName']?.toString() ?? '—';
    final userEmail = t['user']?['email']?.toString() ?? '';
    final userPhone = t['user']?['phoneNumber']?.toString() ?? '';
    final policyName = t['policy']?['policyName']?.toString() ?? '—';
    final catName =
        t['policy']?['category']?['categoryName']?.toString() ?? '—';
    final tierName = t['coverageTier']?['tierName']?.toString() ?? '—';
    final coverageLimit =
        t['coverageTier']?['coverageLimit']?.toString() ?? '—';
    final amount = t['amountPaid']?.toString() ?? '0';
    final date = t['purchaseDate']?.toString().split('T').first ?? '—';
    final address = t['deliveryAddress']?.toString() ?? '—';
    final policyDuration =
        t['policy']?['policyDuration']?['label']?.toString() ?? '—';
    final waitingDays = t['policy']?['waitingPeriodDays']?.toString() ?? '0';
    final claimDays = t['policy']?['claimProcessingDays']?.toString() ?? '0';
    final maxClaim = t['policy']?['maxClaimAmount']?.toString() ?? '—';
    final isPending = brokerStatus.toUpperCase() == 'PENDING';

    Map<String, String> parsedFields = {};
    final rawFieldsValue = t['fieldValues'];
    if (rawFieldsValue != null) {
      try {
        Map<String, dynamic> decoded;
        if (rawFieldsValue is Map) {
          decoded = rawFieldsValue.cast<String, dynamic>();
        } else {
          final str = rawFieldsValue.toString().trim();
          if (str.isNotEmpty && str != 'null') {
            decoded = jsonDecode(str) as Map<String, dynamic>;
          } else {
            decoded = {};
          }
        }
        decoded.forEach(
            (k, v) => parsedFields[_fieldLabel(k)] = v?.toString() ?? '');
      } catch (_) {}
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.82,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: AppTheme.hair(context),
                          borderRadius: BorderRadius.circular(2)))),
              Row(children: [
                Expanded(
                    child: Text(
                        'policy_request_number'.trParams({'id': '$txId'}),
                        style: AppTextStyle.h3(color: AppTheme.ink(context)))),
                BrokerStatusBadge(status: brokerStatus),
              ]),
              const SizedBox(height: 20),
              BrokerInfoSection('Customer Details', {
                'Full Name': userName,
                if (userEmail.isNotEmpty) 'Email': userEmail,
                if (userPhone.isNotEmpty) 'Phone': userPhone,
                if (address.isNotEmpty && address != '—') 'Address': address,
              }),
              BrokerInfoSection('Policy Details', {
                'Policy Name': policyName,
                'Category': catName,
                'Duration': policyDuration,
                'Coverage Tier': tierName,
                'Coverage Limit': '\$$coverageLimit',
                'Premium Paid': '\$$amount',
                'Purchase Date': date,
              }),
              BrokerInfoSection('Policy Terms', {
                'Waiting Period': '$waitingDays days',
                'Claim Processing': '$claimDays days',
                'Max Claim Amount': maxClaim != '—' ? '\$$maxClaim' : '—',
              }),
              if (parsedFields.isNotEmpty) ...[
                const SizedBox(height: 4),
                BrokerInfoSection('Customer Information', parsedFields),
              ],
              if (isPending) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppTheme.warningBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.warning.withValues(alpha: 0.3))),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                    SizedBox(width: 8),
                    Flexible(
                        child: Text(
                            'Review all details before accepting or rejecting this policy request.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.warning))),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onReject(txId);
                    },
                    child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                            color: AppTheme.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppTheme.danger.withValues(alpha: 0.3))),
                        child: Center(
                            child: Text('reject'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.danger)))),
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      onApprove(txId);
                    },
                    child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                            color: AppTheme.successBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                    AppTheme.success.withValues(alpha: 0.3))),
                        child: Center(
                            child: Text('accept'.tr,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.success)))),
                  )),
                ]),
              ],
              if (userPhone.isNotEmpty || userEmail.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(children: [
                  if (userPhone.isNotEmpty)
                    Expanded(
                        child: BrokerBigContactBtn(
                            icon: Icons.phone,
                            label: 'Call',
                            onTap: () => _launch('tel:$userPhone'))),
                  if (userPhone.isNotEmpty && userEmail.isNotEmpty)
                    const SizedBox(width: 10),
                  if (userEmail.isNotEmpty)
                    Expanded(
                        child: BrokerBigContactBtn(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            onTap: () => _launch('mailto:$userEmail'))),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri);
  }

  String _fieldLabel(String key) {
    final spaced = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (m) => ' ${m.group(0)}',
    );
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class BrokerFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color primary;

  const BrokerFilterChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged,
      required this.primary});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: options.map((f) {
            final sel = selected == f;
            return GestureDetector(
              onTap: () => onChanged(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.sienna : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: sel
                          ? AppTheme.sienna
                          : Colors.grey.withValues(alpha: 0.4)),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
              ),
            );
          }).toList(),
        ));
  }
}

class BrokerStatusBadge extends StatelessWidget {
  final String status;
  const BrokerStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
      case 'COMPLETED':
        return AppTheme.success;
      case 'REJECTED':
      case 'CANCELLED':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  Color get _bg {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACCEPTED':
      case 'COMPLETED':
        return AppTheme.successBg;
      case 'REJECTED':
      case 'CANCELLED':
        return AppTheme.dangerBg;
      default:
        return AppTheme.warningBg;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
        child: Text(status,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: _color)),
      );
}

class BrokerSmallContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const BrokerSmallContactBtn(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: AppTheme.siennaBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.hair(context))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: AppTheme.sienna),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.sienna,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

class BrokerBigContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const BrokerBigContactBtn(
      {super.key,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: AppTheme.sienna),
        label: Text(label,
            style: const TextStyle(color: AppTheme.sienna, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.sienna.withValues(alpha: 0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
}

class BrokerInfoSection extends StatelessWidget {
  final String title;
  final Map<String, String> data;
  const BrokerInfoSection(this.title, this.data, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 3,
                height: 13,
                decoration: BoxDecoration(
                    color: AppTheme.sienna,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 6),
            Text(title.toUpperCase(),
                style: AppTextStyle.eyebrow(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.hair(context))),
            child: Column(
                children: data.entries.map((e) {
              final isLast = e.key == data.keys.last;
              return Column(children: [
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                          Flexible(
                              child: Text(e.value,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                                      .copyWith(fontWeight: FontWeight.w600))),
                        ])),
                if (!isLast)
                  Divider(height: 1, color: AppTheme.hair(context)),
              ]);
            }).toList()),
          ),
        ]),
      );
}
