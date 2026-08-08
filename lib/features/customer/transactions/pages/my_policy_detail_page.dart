import 'package:fluttertest/features/customer/browse/services/cart_browse_service.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/services/secure_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/aurora_backdrop.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/customer/browse/services/customer_service.dart';
import 'package:fluttertest/features/customer/transactions/widgets/widgets.dart';
import 'package:fluttertest/features/customer/browse/services/policy_browse_service.dart';
import 'package:fluttertest/features/customer/browse/services/review_service.dart';
import 'package:fluttertest/features/shared/services/delivery_service.dart';

class MyPolicyDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaction;
  const MyPolicyDetailPage({super.key, required this.transaction});

  @override
  State<MyPolicyDetailPage> createState() => _MyPolicyDetailPageState();
}

class _MyPolicyDetailPageState extends State<MyPolicyDetailPage> {
  final _service = PolicyBrowseService();
  final _reviewService = ReviewService();
  final _deliveryService = DeliveryService();
  List<dynamic> _reviews = [];
  bool _loadingReviews = true;
  bool _confirmingDelivery = false;
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentEmail();
    _loadReviews();
  }

  Future<void> _loadCurrentEmail() async {
    final email = await SecureStorageService.getEmail();
    if (mounted) setState(() => _currentEmail = email ?? '');
  }

  Future<void> _loadReviews() async {
    try {
      final pid = widget.transaction['policy']?['policyId'];
      if (pid != null) {
        final id = pid is int ? pid : int.tryParse(pid.toString()) ?? 0;
        final data = await _reviewService.getPolicyReviews(id);
        if (mounted) setState(() => _reviews = data);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingReviews = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))));

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '—';
    try {
      final dt = DateTime.parse(d);
      const m = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${m[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return d.split('T').first;
    }
  }

  String _fieldLabel(String key) {
    final spaced = key
        .replaceAll('_', ' ')
        .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .trim();
    return spaced
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Map<String, String> get _parsedFields {
    final raw = widget.transaction['fieldValues'];
    if (raw == null) return {};
    try {
      Map<String, dynamic> decoded;
      if (raw is Map) {
        decoded = raw.cast<String, dynamic>();
      } else {
        final s = raw.toString().trim();
        decoded = s.isNotEmpty && s != 'null'
            ? (jsonDecode(s) as Map<String, dynamic>)
            : {};
      }
      final result = <String, String>{};
      decoded.forEach((k, v) => result[_fieldLabel(k)] = v?.toString() ?? '');
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _confirmDelivery() async {
    if (_confirmingDelivery) return;
    final rawId = widget.transaction['transactionId'];
    final txId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    if (txId == null) {
      _snack('Transaction not found');
      return;
    }
    setState(() => _confirmingDelivery = true);
    try {
      await _deliveryService.markDelivered(txId);
      if (!mounted) return;
      setState(() {
        widget.transaction['deliveryStatus'] = 'DELIVERED';
        widget.transaction['deliveredAt'] = DateTime.now().toIso8601String();
      });
      _snack('Delivery confirmed. The broker can now confirm payment.');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _confirmingDelivery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.transaction;
    final policy = tx['policy'] as Map<String, dynamic>? ?? {};
    final name = policy['policyName']?.toString() ?? 'Policy';
    final cat = policy['category']?['categoryName']?.toString() ?? '';
    final status = tx['brokerStatus']?.toString().toUpperCase() ?? 'PENDING';

    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHero(name, cat, status, tx)),
        SliverToBoxAdapter(child: _buildTimeline(status, tx)),
        SliverToBoxAdapter(child: _buildDelivery(tx)),
        SliverToBoxAdapter(child: _buildPolicyDetails(tx, policy)),
        if (_parsedFields.isNotEmpty)
          SliverToBoxAdapter(child: _buildMyDetails()),
        SliverToBoxAdapter(child: _buildReviews(policy)),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ]),
    );
  }

  String _upper(Map<String, dynamic> tx, String key) =>
      tx[key]?.toString().toUpperCase() ?? '';

  bool _isPaid(Map<String, dynamic> tx) =>
      _upper(tx, 'paymentStatus') == 'PAID';

  bool _hasDeliveryFlow(Map<String, dynamic> tx) {
    final method = _upper(tx, 'paymentMethod');
    final delivery = _upper(tx, 'deliveryStatus');
    return method == 'COD' ||
        method == 'CASH' ||
        method == 'CASH_ON_DELIVERY' ||
        {
          'AWAITING_BROKER',
          'ACCEPTED_BY_BROKER',
          'SHIPPED',
          'DELIVERED',
          'NOT_RECEIVED',
          'REJECTED_BY_BROKER',
        }.contains(delivery);
  }

  bool get _hasCurrentUserReview {
    if (_currentEmail.trim().isEmpty) return false;
    final email = _currentEmail.trim().toLowerCase();
    return _reviews.any((raw) {
      if (raw is! Map) return false;
      final review = raw;
      final user = review['user'];
      final reviewEmail = review['customerEmail']?.toString() ??
          (user is Map ? user['email']?.toString() : null) ??
          '';
      return reviewEmail.trim().toLowerCase() == email;
    });
  }

  DateTime? _parseDate(dynamic raw) =>
      raw == null ? null : DateTime.tryParse(raw.toString());

  bool _coverageStarted(Map<String, dynamic> tx) {
    final activeDate = _parseDate(tx['policyActiveDate']);
    return _isPaid(tx) &&
        activeDate != null &&
        !DateTime.now().isBefore(activeDate);
  }

  ({String label, Color color}) _heroBadge(
      String status, Map<String, dynamic> tx) {
    final isPending = status == 'PENDING';
    final isAccepted = status == 'ACCEPTED';
    final success =
        AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success;
    final danger =
        AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
    final waiting = AppTheme.muted(context);

    if (isPending) return (label: 'Pending Review', color: AppTheme.warning);
    if (!isAccepted) return (label: 'Rejected', color: danger);

    final delivery = _upper(tx, 'deliveryStatus');
    final hasDelivery = _hasDeliveryFlow(tx);
    final paid = _isPaid(tx);

    if (delivery == 'NOT_RECEIVED') {
      return (label: 'Delivery Issue', color: danger);
    }
    if (delivery == 'REJECTED_BY_BROKER') {
      return (label: 'Delivery Rejected', color: danger);
    }
    if (hasDelivery && delivery == 'ACCEPTED_BY_BROKER') {
      return (label: 'Preparing', color: waiting);
    }
    if (hasDelivery && delivery == 'SHIPPED') {
      return (label: 'Shipped', color: waiting);
    }
    if (!paid) {
      return (label: 'Awaiting Payment', color: waiting);
    }
    if (!_coverageStarted(tx)) {
      return (label: 'Waiting Period', color: waiting);
    }
    return (label: 'Active', color: success);
  }

  Widget _buildHero(
      String name, String cat, String status, Map<String, dynamic> tx) {
    final badge = _heroBadge(status, tx);

    return AuroraBackdrop(
        child: Container(
      width: double.infinity,
      color: AppTheme.siennaSoft,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 24,
          left: AppTheme.screenPad,
          right: AppTheme.screenPad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: AppTheme.surface(context),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.hair(context))),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 15, color: AppTheme.ink(context)))),
        const SizedBox(height: 20),
        Row(children: [
          Text(cat.toUpperCase(),
              style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
          const Spacer(),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(badge.label,
                  style: AppTextStyle.eyebrow(color: badge.color))),
        ]),
        const SizedBox(height: 6),
        Text(name, style: AppTextStyle.h2(color: AppTheme.ink(context))),
      ]),
    ));
  }

  Widget _buildDelivery(Map<String, dynamic> tx) {
    final dStatus = (tx['deliveryStatus']?.toString() ?? '').toUpperCase();
    final method = (tx['paymentMethod']?.toString() ?? '').toUpperCase();
    final isCod =
        method == 'COD' || method == 'CASH' || method == 'CASH_ON_DELIVERY';

    const flow = {
      'AWAITING_BROKER',
      'ACCEPTED_BY_BROKER',
      'SHIPPED',
      'DELIVERED',
      'REJECTED_BY_BROKER'
    };
    if (!isCod && !flow.contains(dStatus)) return const SizedBox.shrink();
    if (dStatus.isEmpty) return const SizedBox.shrink();

    final shipmentId = tx['shipmentId']?.toString();
    final trackingUrl = tx['trackingUrl']?.toString();
    final carrier = tx['carrierName']?.toString();

    String label;
    Color color;
    switch (dStatus) {
      case 'SHIPPED':
        label = 'delivery_shipped'.tr;
        color = AppTheme.sienna;
        break;
      case 'DELIVERED':
        label = 'delivery_delivered'.tr;
        color =
            AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success;
        break;
      case 'ACCEPTED_BY_BROKER':
        label = 'delivery_preparing'.tr;
        color = AppTheme.warning;
        break;
      case 'REJECTED_BY_BROKER':
        label = 'delivery_rejected'.tr;
        color =
            AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
        break;
      default:
        label = 'delivery_awaiting'.tr;
        color = AppTheme.muted(context);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.hair(context)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.local_shipping_outlined, size: 16, color: color),
            const SizedBox(width: 8),
            Text('delivery_tracking'.tr,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999)),
              child: Text(label,
                  style: AppTextStyle.eyebrow(color: color)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 9)),
            ),
          ]),
          if (shipmentId != null && shipmentId.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text('${'shipment_id'.tr}: ',
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              Expanded(
                child: Text(shipmentId,
                    style: AppTextStyle.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppTheme.ink(context))),
              ),
            ]),
            if (carrier != null && carrier.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text('${'carrier'.tr}: $carrier',
                  style:
                      AppTextStyle.bodySmall(color: AppTheme.muted(context))),
            ],
            if (trackingUrl != null && trackingUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              SiennaButton(
                label: 'track_shipment'.tr,
                icon: Icons.open_in_new_rounded,
                height: 44,
                onTap: () async {
                  var raw = trackingUrl.trim();
                  if (!raw.startsWith('http://') &&
                      !raw.startsWith('https://')) {
                    raw = 'https://$raw';
                  }
                  final uri = Uri.parse(raw);
                  try {
                    final ok = await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                    if (!ok) {
                      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                    }
                  } catch (_) {
                    try {
                      await launchUrl(uri, mode: LaunchMode.platformDefault);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('could_not_open_link'.tr),
                            behavior: SnackBarBehavior.floating));
                      }
                    }
                  }
                },
              ),
            ],
            if (dStatus == 'SHIPPED') ...[
              const SizedBox(height: 10),
              SiennaButton(
                label: 'Confirm Delivery',
                loading: _confirmingDelivery,
                onTap: _confirmDelivery,
                icon: Icons.done_all_outlined,
              ),
            ],
          ] else if (dStatus != 'REJECTED_BY_BROKER') ...[
            const SizedBox(height: 8),
            Text('delivery_not_shipped_yet'.tr,
                style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
          ],
        ]),
      ),
    );
  }

  Widget _buildTimeline(String status, Map<String, dynamic> tx) {
    final isAccepted = status == 'ACCEPTED';
    final isRejected = status == 'REJECTED';
    final isPending = status == 'PENDING';

    final steps = <TimelineStep>[
      TimelineStep(
          label: 'Submitted',
          sublabel: _fmt(tx['purchaseDate']?.toString()),
          done: true,
          icon: Icons.check_circle_outline),
      TimelineStep(
          label: 'Under Review',
          sublabel: 'Broker reviewing your policy',
          done: !isPending,
          active: isPending,
          icon: Icons.pending_outlined),
      TimelineStep(
          label: isRejected ? 'Rejected' : 'Accepted',
          sublabel: isRejected
              ? 'Broker declined this policy'
              : isAccepted
                  ? 'Broker accepted your application'
                  : 'Awaiting approval',
          done: isAccepted,
          failed: isRejected,
          icon: isRejected ? Icons.cancel_outlined : Icons.verified_outlined),
    ];
    if (isAccepted) {
      final eligibleStr =
          _isPaid(tx) ? tx['policyActiveDate']?.toString() : null;
      final activeStr = tx['policyActiveDate']?.toString();
      bool coverageActive = false;
      String coverageSub = _hasDeliveryFlow(tx)
          ? 'Delivery and payment must finish first'
          : 'Payment must be confirmed first';
      if (eligibleStr != null) {
        try {
          final eligible = DateTime.parse(eligibleStr);
          coverageActive = DateTime.now().isAfter(eligible);
          if (coverageActive) {
            coverageSub = 'Coverage is active';
          } else {
            final days = eligible.difference(DateTime.now()).inDays + 1;
            coverageSub =
                'Active on ${_fmt(eligibleStr)} · in $days day${days == 1 ? '' : 's'}';
          }
        } catch (_) {}
      } else if (activeStr != null) {
        try {
          final active = DateTime.parse(activeStr);
          coverageActive = DateTime.now().isAfter(active);
          coverageSub = coverageActive
              ? 'Coverage is active'
              : 'Active on ${_fmt(activeStr)}';
        } catch (_) {}
      }
      steps.add(TimelineStep(
          label: 'Active',
          sublabel: coverageSub,
          done: coverageActive,
          active: _isPaid(tx) && !coverageActive,
          icon: Icons.shield_outlined));
    }

    return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 20, AppTheme.screenPad, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(
              title: 'policy_status'.tr.isEmpty
                  ? 'Policy Status'
                  : 'Policy Status'),
          const SizedBox(height: 12),
          PremiumCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                  children: steps
                      .asMap()
                      .entries
                      .map((e) => _buildStep(e.value,
                          isLast: e.key == steps.length - 1))
                      .toList())),
        ]));
  }

  Widget _buildStep(TimelineStep step, {required bool isLast}) {
    final Color color;
    if (step.failed)
      color = AppTheme.isDark(context) ? AppTheme.darkDanger : AppTheme.danger;
    else if (step.done || step.active)
      color = step.done
          ? (AppTheme.isDark(context) ? AppTheme.darkSuccess : AppTheme.success)
          : AppTheme.warning;
    else
      color = AppTheme.muted(context);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
                border: Border.all(color: color.withValues(alpha: 0.4))),
            child: Icon(step.icon, size: 14, color: color)),
        if (!isLast)
          Container(
              width: 1,
              height: 28,
              color: AppTheme.hair(context),
              margin: const EdgeInsets.symmetric(vertical: 2)),
      ]),
      const SizedBox(width: 12),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.label,
                        style:
                            AppTextStyle.bodySmall(color: AppTheme.ink(context))
                                .copyWith(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(step.sublabel,
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ]))),
    ]);
  }

  Widget _buildPolicyDetails(
      Map<String, dynamic> tx, Map<String, dynamic> policy) {
    final tier = tx['coverageTier'];
    final paid = tx['amountPaid']?.toString() ?? '0';
    final date = _fmt(tx['purchaseDate']?.toString());

    String renewDate = '—';
    try {
      final activeStr =
          tx['policyActiveDate']?.toString() ?? tx['purchaseDate']?.toString();
      if (activeStr != null) {
        final activeDate = DateTime.parse(activeStr);
        final durationLabel = (policy['policyDuration']?['label'] ??
                policy['policyDuration']?['duration'] ??
                '')
            .toString()
            .toLowerCase();

        int months = 12;
        final match = RegExp(r'(\d+)\s*(month|year)').firstMatch(durationLabel);
        if (match != null) {
          final n = int.parse(match.group(1)!);
          months = match.group(2) == 'year' ? n * 12 : n;
        } else if (durationLabel.contains('year')) {
          months = 12;
        } else if (durationLabel.contains('month')) {
          months = 1;
        }
        final expiry = DateTime(
            activeDate.year, activeDate.month + months, activeDate.day);
        renewDate = _fmt(expiry.toIso8601String());
      }
    } catch (_) {}

    return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(
              title: 'policy_details'.tr.isEmpty
                  ? 'Policy Details'
                  : 'Policy Details'),
          const SizedBox(height: 10),
          PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                DetailRow(
                    'Coverage Tier', tier?['tierName']?.toString() ?? '—'),
                DetailRow(
                    'Coverage Limit',
                    tier?['coverageLimit'] != null
                        ? '\$${tier!['coverageLimit']}'
                        : '—'),
                DetailRow('Premium Paid', '\$$paid'),
                DetailRow('Duration',
                    policy['policyDuration']?['label']?.toString() ?? '—'),
                DetailRow('Issued', date),
                DetailRow('Renews', renewDate),
                DetailRow(
                    'Waiting Period',
                    policy['waitingPeriodDays'] != null
                        ? '${policy['waitingPeriodDays']} days'
                        : '—'),
                DetailRow(
                    'Claim Processing',
                    policy['claimProcessingDays'] != null
                        ? '${policy['claimProcessingDays']} days'
                        : '—'),
                DetailRow(
                    'Max Claim Amount',
                    policy['maxClaimAmount'] != null
                        ? '\$${policy['maxClaimAmount']}'
                        : '—',
                    last: true),
              ])),
        ]));
  }

  Widget _buildMyDetails() {
    final fields = _parsedFields;
    return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(title: 'Your Submitted Details'),
          const SizedBox(height: 10),
          PremiumCard(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: fields.entries
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: AppTheme.accentSoft(context),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color:
                                      AppTheme.sienna.withValues(alpha: 0.2))),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.key,
                                    style: AppTextStyle.eyebrow(
                                            color: AppTheme.muted(context))
                                        .copyWith(fontSize: 9)),
                                const SizedBox(height: 3),
                                Text(e.value,
                                    style: AppTextStyle.bodySmall(
                                            color: AppTheme.ink(context))
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ]),
                        ))
                    .toList(),
              )),
        ]));
  }

  Widget _buildReviews(Map<String, dynamic> policy) {
    final isAccepted =
        (widget.transaction['brokerStatus']?.toString().toUpperCase() ?? '') ==
            'ACCEPTED';
    final hasReviewed = _hasCurrentUserReview;
    return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.screenPad, 16, AppTheme.screenPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: SectionTitle(title: 'Reviews')),
            if (isAccepted && !hasReviewed)
              GestureDetector(
                  onTap: _showReviewForm,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: AppTheme.siennaSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: AppTheme.sienna.withValues(alpha: 0.3))),
                      child: Text('write_review'.tr,
                          style: AppTextStyle.eyebrow(color: AppTheme.sienna))))
            else if (isAccepted && hasReviewed)
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: (AppTheme.isDark(context)
                                  ? AppTheme.darkSuccess
                                  : AppTheme.success)
                              .withValues(alpha: 0.3))),
                  child: Text('Reviewed',
                      style: AppTextStyle.eyebrow(
                          color: AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success))),
          ]),
          const SizedBox(height: 10),
          if (_loadingReviews)
            const Center(
                child: CircularProgressIndicator(color: AppTheme.sienna))
          else if (_reviews.isEmpty)
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.siennaSoft,
                    borderRadius: BorderRadius.circular(28)),
                child: Center(
                    child: Text('no_reviews_yet'.tr,
                        style: AppTextStyle.bodySmall(color: AppTheme.sienna))))
          else
            ..._reviews.map((r) {
              final review = r as Map<String, dynamic>;
              final rating = review['rating'] as int? ?? 0;
              final text = review['reviewText']?.toString() ?? '';
              return PremiumCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                    i < rating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 14))),
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(text,
                              style: AppTextStyle.bodySmall(
                                  color: AppTheme.ink2(context)))
                        ],
                      ]));
            }),
        ]));
  }

  void _showReviewForm() {
    if (_hasCurrentUserReview) {
      _snack('You already reviewed this policy');
      return;
    }
    int selectedRating = 0;
    final ctrl = TextEditingController();
    bool submitting = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => StatefulBuilder(
            builder: (ctx, setS) => Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom),
                child: Container(
                    padding: const EdgeInsets.all(AppTheme.screenPad),
                    decoration: BoxDecoration(
                        color: AppTheme.surface(context),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppTheme.radiusLg))),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppTheme.hair(context),
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(height: 16),
                      Text('write_review'.tr,
                          style: AppTextStyle.h3(color: AppTheme.ink(context))),
                      const SizedBox(height: 16),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              5,
                              (i) => GestureDetector(
                                  onTap: () =>
                                      setS(() => selectedRating = i + 1),
                                  child: Icon(
                                      i < selectedRating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 36)))),
                      const SizedBox(height: 16),
                      PremiumField(
                          controller: ctrl,
                          label: 'write_a_review'.tr,
                          hint: 'share_your_experience'.tr,
                          prefixIcon: Icons.comment_outlined,
                          maxLines: 3),
                      const SizedBox(height: 16),
                      SiennaButton(
                          label: 'Submit Review',
                          loading: submitting,
                          onTap: () async {
                            if (selectedRating == 0) {
                              _snack('Please select a rating');
                              return;
                            }
                            setS(() => submitting = true);
                            try {
                              final pid =
                                  widget.transaction['policy']?['policyId'];
                              if (pid == null)
                                throw Exception('Policy not found');
                              final id = pid is int
                                  ? pid
                                  : int.tryParse(pid.toString()) ?? 0;
                              await _reviewService.submitReview(
                                  policyId: id,
                                  rating: selectedRating,
                                  reviewText: ctrl.text);
                              if (mounted) {
                                Navigator.pop(ctx);
                                _loadReviews();
                                _snack('Review submitted!');
                              }
                            } catch (e) {
                              _snack(e.toString());
                            } finally {
                              setS(() => submitting = false);
                            }
                          }),
                    ])))));
  }
}
