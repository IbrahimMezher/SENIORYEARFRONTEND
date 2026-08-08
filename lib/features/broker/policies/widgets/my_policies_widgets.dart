import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/broker/claims/services/broker_claims_service.dart';
import 'package:fluttertest/features/broker/policies/services/policy_service.dart';
import 'package:fluttertest/features/broker/policies/pages/add_policy.dart';

class PolicyCard extends StatelessWidget {
  final Map<String, dynamic> policy;
  final Map<String, IconData> catIcons;
  final String catName;
  final VoidCallback onEdit;
  const PolicyCard(
      {required this.policy,
      required this.catIcons,
      required this.catName,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final name = policy['policyName']?.toString() ?? '';
    final tiers = (policy['coverageTiers'] as List? ?? []);
    final status = policy['status']?.toString() ?? 'DRAFT';
    final isLive =
        status.toUpperCase() == 'ACTIVE' || status.toUpperCase() == 'PUBLISHED';
    final icon = catIcons.entries
        .firstWhere((e) => catName.toLowerCase().contains(e.key),
            orElse: () => const MapEntry('', Icons.policy_outlined))
        .value;
    final txList = (policy['transactions'] as List? ??
        policy['policyTransactions'] as List? ??
        []);
    final acceptedTx = txList
        .where((t) =>
            (t['brokerStatus']?.toString().toUpperCase() ?? '') == 'ACCEPTED')
        .toList();
    final sold = acceptedTx.length;
    final revenue = acceptedTx.fold(
        0.0,
        (s, t) =>
            s +
            (double.tryParse((t['amountPaid']?.toString() ?? '0')
                    .replaceAll(RegExp(r'[^\d.]'), '')) ??
                0.0));
    final reviews = (policy['reviews'] as List? ?? []);
    final avgRating = reviews.isEmpty
        ? 0.0
        : reviews.fold(
                0.0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
            reviews.length;
    final prices = tiers
        .map((t) =>
            double.tryParse((t['premiumPrice']?.toString() ?? '0')
                .replaceAll(RegExp(r'[^\d.]'), '')) ??
            0.0)
        .where((v) => v > 0)
        .toList();
    final minPrice = prices.isEmpty ? null : (prices..sort()).first;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: AppTheme.cardDecoration(context),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppTheme.accentSoft(context),
                        borderRadius: BorderRadius.circular(AppTheme.radius)),
                    child: Icon(icon, color: AppTheme.sienna, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: AppTextStyle.bodyMedium(
                                  color: AppTheme.ink(context))
                              .copyWith(
                                  fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text(catName,
                            style: AppTextStyle.eyebrow(
                                color: AppTheme.muted(context))),
                        if (tiers.isNotEmpty) ...[
                          Text('  -  ',
                              style: AppTextStyle.eyebrow(
                                  color: AppTheme.muted(context))),
                          Text(
                              '${tiers.length} tier${tiers.length == 1 ? '' : 's'}',
                              style: AppTextStyle.eyebrow(
                                  color: AppTheme.muted(context))),
                        ],
                      ]),
                    ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: isLive
                              ? (AppTheme.isDark(context)
                                  ? AppTheme.darkSuccess.withValues(alpha: 0.14)
                                  : AppTheme.successBg)
                              : AppTheme.warningBg,
                          borderRadius: BorderRadius.circular(999)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 86),
                        child: Text(isLive ? 'LIVE' : status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: AppTextStyle.eyebrow(
                                color: isLive
                                    ? (AppTheme.isDark(context)
                                        ? AppTheme.darkSuccess
                                        : AppTheme.success)
                                    : AppTheme.warning)),
                      )),
                  if (minPrice != null) ...[
                    const SizedBox(height: 6),
                    Text('\$${minPrice.toStringAsFixed(0)}/mo',
                        style: AppTextStyle.mono(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppTheme.ink(context))),
                  ],
                ]),
              ])),
          if (reviews.isNotEmpty) ...[
            Divider(height: 1, color: AppTheme.hair(context)),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  ...List.generate(
                      5,
                      (i) => Icon(
                          i < avgRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: AppTheme.warning)),
                  const SizedBox(width: 6),
                  Text(avgRating.toStringAsFixed(1),
                      style: AppTextStyle.mono(
                          size: 12,
                          weight: FontWeight.w600,
                          color: AppTheme.ink(context))),
                  const SizedBox(width: 4),
                  Text('(${reviews.length})',
                      style:
                          AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showReviews(context, reviews, name),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('view'.tr,
                          style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right,
                          size: 14, color: AppTheme.sienna),
                    ]),
                  ),
                ])),
          ],
          Divider(height: 1, color: AppTheme.hair(context)),
          Row(children: [
            MetricCell('SOLD', '$sold'),
            Container(width: 1, height: 28, color: AppTheme.hair(context)),
            MetricCell('REVENUE',
                '\$${revenue >= 1000 ? '${(revenue / 1000).toStringAsFixed(1)}k' : revenue.toStringAsFixed(0)}'),
            Container(width: 1, height: 28, color: AppTheme.hair(context)),
            MetricCell('REVIEWS', reviews.isEmpty ? '-' : '${reviews.length}'),
          ]),
        ]),
      ),
    );
  }

  void _showReviews(BuildContext context, List reviews, String policyName) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ReviewsSheet(reviews: reviews, policyName: policyName));
  }
}

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final Map<String, IconData> catIcons;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onShip;
  final VoidCallback? onPaid;
  final VoidCallback? onNotReceived;
  final bool busy;
  const RequestCard(
      {required this.tx,
      required this.catIcons,
      this.onApprove,
      this.onReject,
      this.onShip,
      this.onPaid,
      this.onNotReceived,
      this.busy = false});

  String _fmt(String? d) {
    if (d == null || d.isEmpty) return '-';
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

  String _assetUrl(String value) {
    final path = value.trim();
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final baseUrl = ApiService().baseUrl;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  bool _isImageValue(String value) {
    final lower = value.toLowerCase().split('?').first;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.contains('/category-fields/images/');
  }

  bool _isPdfValue(String value) {
    final lower = value.toLowerCase().split('?').first;
    return lower.endsWith('.pdf') ||
        lower.contains('/category-fields/documents/');
  }

  void _openImagePreview(BuildContext context, String title, String value) {
    final url = _assetUrl(value);
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: AppTheme.surface(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
            maxWidth: 520,
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
              child: Row(children: [
                Expanded(
                  child: Text(title,
                      style:
                          AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close,
                      size: 18, color: AppTheme.muted(context)),
                ),
              ]),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Padding(
                    padding: const EdgeInsets.all(32),
                    child: Icon(Icons.broken_image_outlined,
                        size: 42, color: AppTheme.muted(context)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: GestureDetector(
                onTap: () => launchUrl(Uri.parse(url)),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.open_in_new,
                      size: 14, color: AppTheme.sienna),
                  const SizedBox(width: 6),
                  Text('Open externally',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _fieldValueCard(BuildContext context, MapEntry<String, String> e) {
    final value = e.value.trim();
    final image = _isImageValue(value);
    final pdf = _isPdfValue(value);
    return Container(
      constraints: BoxConstraints(maxWidth: image ? 178 : 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.hairStrong(context)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(e.key,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))
                .copyWith(fontSize: 9)),
        const SizedBox(height: 6),
        if (image)
          GestureDetector(
            onTap: () => _openImagePreview(context, e.key, value),
            child: Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  _assetUrl(value),
                  width: 150,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 150,
                    height: 96,
                    color: AppTheme.hair(context),
                    child: Icon(Icons.broken_image_outlined,
                        color: AppTheme.muted(context)),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Icon(Icons.open_in_full,
                      size: 13, color: Colors.white),
                ),
              ),
            ]),
          )
        else if (pdf)
          GestureDetector(
            onTap: () => launchUrl(Uri.parse(_assetUrl(value))),
            child: Row(children: [
              Icon(Icons.picture_as_pdf_outlined,
                  size: 16, color: AppTheme.ink2(context)),
              const SizedBox(width: 6),
              Expanded(
                child: Text('View PDF',
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ]),
          )
        else
          Text(value,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final name = tx['policy']?['policyName']?.toString() ?? 'Policy';
    final cat = tx['policy']?['category']?['categoryName']?.toString() ?? '';
    final tier = tx['coverageTier']?['tierName']?.toString() ?? '-';
    final limit = tx['coverageTier']?['coverageLimit']?.toString() ?? '-';
    final paid = tx['amountPaid']?.toString() ?? '0';
    final status = tx['brokerStatus']?.toString().toUpperCase() ?? 'PENDING';
    final date = _fmt(tx['purchaseDate']?.toString());
    final userName = tx['user']?['fullName']?.toString() ?? '-';
    final userEmail = tx['user']?['email']?.toString() ?? '';
    final userPhone = tx['user']?['phoneNumber']?.toString() ?? '';
    final deliveryAddress = tx['deliveryAddress']?.toString() ?? '';
    final paymentMethod = tx['paymentMethod']?.toString() ?? '';
    final deliveryPrice = tx['deliveryPrice']?.toString() ?? '';
    final icon = catIcons.entries
        .firstWhere((e) => cat.toLowerCase().contains(e.key),
            orElse: () => const MapEntry('', Icons.policy_outlined))
        .value;
    final isPending = status == 'PENDING';
    final isAccepted = status == 'ACCEPTED';

    final rawFields = tx['fieldValues'];
    Map<String, String> parsedFields = {};
    if (rawFields != null) {
      try {
        Map<String, dynamic> decoded;
        if (rawFields is Map) {
          decoded = rawFields.cast<String, dynamic>();
        } else {
          final s = rawFields.toString().trim();
          decoded = s.isNotEmpty && s != 'null'
              ? (jsonDecode(s) as Map<String, dynamic>)
              : {};
        }
        decoded.forEach(
            (k, v) => parsedFields[_fieldLabel(k)] = v?.toString() ?? '');
      } catch (_) {}
    }

    Color sc;
    Color sbg;
    if (isAccepted) {
      sc = dark ? AppTheme.darkSuccess : AppTheme.success;
      sbg = dark
          ? AppTheme.darkSuccess.withValues(alpha: 0.12)
          : AppTheme.successBg;
    } else if (status == 'REJECTED') {
      sc = dark ? AppTheme.darkDanger : AppTheme.danger;
      sbg = dark
          ? AppTheme.darkDanger.withValues(alpha: 0.12)
          : AppTheme.dangerBg;
    } else {
      sc = AppTheme.warning;
      sbg = AppTheme.warningBg;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.cardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: AppTheme.accentSoft(context),
                      borderRadius: BorderRadius.circular(28)),
                  child: Icon(icon, color: AppTheme.sienna, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.bodyMedium(
                                color: AppTheme.ink(context))
                            .copyWith(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('$tier - Coverage \$$limit',
                        style: AppTextStyle.eyebrow(
                            color: AppTheme.muted(context))),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: sbg, borderRadius: BorderRadius.circular(999)),
                  child: Text(status, style: AppTextStyle.eyebrow(color: sc))),
            ])),
        Container(
          color: AppTheme.surface2(context),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Icon(Icons.person_outline,
                size: 14, color: AppTheme.muted(context)),
            const SizedBox(width: 6),
            Expanded(
                child: Text(userName,
                    style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                        .copyWith(fontSize: 12, fontWeight: FontWeight.w600))),
            Text(date,
                style: AppTextStyle.mono(
                    size: 10, color: AppTheme.muted(context))),
          ]),
        ),
        if (deliveryAddress.isNotEmpty ||
            paymentMethod.isNotEmpty ||
            userPhone.isNotEmpty) ...[
          Divider(height: 1, color: AppTheme.hair(context)),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: Text('delivery_details'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (deliveryAddress.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 14, color: AppTheme.muted(context)),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(deliveryAddress,
                                        style: AppTextStyle.bodySmall(
                                                color: AppTheme.ink(context))
                                            .copyWith(fontSize: 12))),
                              ])),
                    if (userPhone.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.phone_outlined,
                                size: 14, color: AppTheme.muted(context)),
                            const SizedBox(width: 6),
                            Text(userPhone,
                                style: AppTextStyle.bodySmall(
                                        color: AppTheme.ink(context))
                                    .copyWith(fontSize: 12)),
                          ])),
                    if (userEmail.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.email_outlined,
                                size: 14, color: AppTheme.muted(context)),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(userEmail,
                                    style: AppTextStyle.bodySmall(
                                            color: AppTheme.ink(context))
                                        .copyWith(fontSize: 12))),
                          ])),
                    if (paymentMethod.isNotEmpty)
                      Row(children: [
                        Icon(Icons.payments_outlined,
                            size: 14, color: AppTheme.muted(context)),
                        const SizedBox(width: 6),
                        Text(
                            '$paymentMethod${deliveryPrice.isNotEmpty && deliveryPrice != '0' ? " - Delivery: \$$deliveryPrice" : ""}',
                            style: AppTextStyle.bodySmall(
                                    color: AppTheme.ink(context))
                                .copyWith(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                  ])),
        ],
        if (parsedFields.isNotEmpty) ...[
          Divider(height: 1, color: AppTheme.hair(context)),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
              child: Text('customer_details'.tr,
                  style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: parsedFields.entries
                    .map((e) => _fieldValueCard(context, e))
                    .toList(),
              )),
        ],
        Divider(height: 1, color: AppTheme.hair(context)),
        Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('premium'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                Text('\$$paid',
                    style: AppTextStyle.mono(
                        size: 16,
                        weight: FontWeight.w700,
                        color: AppTheme.ink(context))),
              ]),
              const Spacer(),
              if (isPending && busy)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.sienna,
                          strokeCap: StrokeCap.round)),
                )
              else if (isPending) ...[
                GestureDetector(
                    onTap: onReject,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: (dark ? AppTheme.darkDanger : AppTheme.danger)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: (dark
                                        ? AppTheme.darkDanger
                                        : AppTheme.danger)
                                    .withValues(alpha: 0.3))),
                        child: Text('reject'.tr,
                            style: AppTextStyle.bodySmall(
                                    color: dark
                                        ? AppTheme.darkDanger
                                        : AppTheme.danger)
                                .copyWith(fontWeight: FontWeight.w700)))),
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: onApprove,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                            color: AppTheme.sienna,
                            borderRadius: BorderRadius.circular(28)),
                        child: Text('accept'.tr,
                            style: AppTextStyle.bodySmall(color: Colors.white)
                                .copyWith(fontWeight: FontWeight.w700)))),
              ],
            ])),
        if (onShip != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: busy ? null : onShip,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: busy ? AppTheme.hair(context) : AppTheme.sienna,
                  borderRadius: BorderRadius.circular(28)),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 15, color: AppTheme.siennaFg),
                        const SizedBox(width: 8),
                        Text('mark_shipped'.tr,
                            style:
                                AppTextStyle.button(color: AppTheme.siennaFg)),
                      ]),
              ),
            ),
          ),
        ],
        if (onPaid != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: busy ? null : onPaid,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: busy
                      ? AppTheme.hair(context)
                      : (AppTheme.isDark(context)
                          ? AppTheme.darkSuccess
                          : AppTheme.success),
                  borderRadius: BorderRadius.circular(28)),
              child: Center(
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.payments_outlined,
                            size: 15, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('mark_paid'.tr,
                            style: AppTextStyle.button(color: Colors.white)),
                      ]),
              ),
            ),
          ),
        ],
        if (onNotReceived != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: busy ? null : onNotReceived,
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                  color: (AppTheme.isDark(context)
                          ? AppTheme.darkDanger
                          : AppTheme.danger)
                      .withValues(alpha: 0.12),
                  border: Border.all(
                      color: (AppTheme.isDark(context)
                              ? AppTheme.darkDanger
                              : AppTheme.danger)
                          .withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(28)),
              child: Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.report_gmailerrorred_outlined,
                      size: 15,
                      color: AppTheme.isDark(context)
                          ? AppTheme.darkDanger
                          : AppTheme.danger),
                  const SizedBox(width: 8),
                  Text('Mark as Not Received',
                      style: AppTextStyle.button(
                          color: AppTheme.isDark(context)
                              ? AppTheme.darkDanger
                              : AppTheme.danger)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

class ReviewsSheet extends StatelessWidget {
  final List reviews;
  final String policyName;
  const ReviewsSheet({required this.reviews, required this.policyName});

  @override
  Widget build(BuildContext context) {
    final avgRating = reviews.fold(
            0.0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
        reviews.length;
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
          color: AppTheme.bg(context),
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg))),
      child: Column(children: [
        Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: AppTheme.hair(context),
                borderRadius: BorderRadius.circular(99))),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(policyName,
                        style: AppTextStyle.h3(color: AppTheme.ink(context)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      ...List.generate(
                          5,
                          (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: AppTheme.warning)),
                      const SizedBox(width: 6),
                      Text(
                          '${avgRating.toStringAsFixed(1)} - ${reviews.length} review${reviews.length == 1 ? '' : 's'}',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.ink2(context))),
                    ]),
                  ])),
              GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: AppTheme.surface(context),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.hair(context))),
                      child: Icon(Icons.close,
                          size: 16, color: AppTheme.muted(context)))),
            ])),
        Divider(
            height: 24,
            indent: 20,
            endIndent: 20,
            color: AppTheme.hair(context)),
        Expanded(
            child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: reviews.length,
          separatorBuilder: (_, __) =>
              Divider(height: 24, color: AppTheme.hair(context)),
          itemBuilder: (context, i) {
            final r = reviews[i] as Map<String, dynamic>;
            final rating = (r['rating'] as num?)?.toInt() ?? 0;
            final text = r['reviewText']?.toString() ?? '';
            final user = r['customerName']?.toString() ??
                r['user']?['fullName']?.toString() ??
                'Customer';
            final email = r['customerEmail']?.toString() ??
                r['user']?['email']?.toString() ??
                '';
            final phone = r['customerPhone']?.toString() ??
                r['user']?['phoneNumber']?.toString() ??
                '';
            final date = r['createdAt']?.toString().split('T').first ?? '';
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Row(
                        children: List.generate(
                            5,
                            (j) => Icon(
                                j < rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: AppTheme.warning))),
                    const Spacer(),
                    Text(date,
                        style:
                            AppTextStyle.eyebrow(color: AppTheme.muted(context))
                                .copyWith(fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                  Text(user,
                      style:
                          AppTextStyle.bodySmall(color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600)),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(text,
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.ink2(context)))
                  ],
                  if (email.isNotEmpty || phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (email.isNotEmpty)
                        _ReviewContactChip(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          onTap: () => launchUrl(Uri(
                            scheme: 'mailto',
                            path: email,
                            queryParameters: {
                              'subject': 'Review follow-up for $policyName',
                            },
                          )),
                        ),
                      if (phone.isNotEmpty)
                        _ReviewContactChip(
                          icon: Icons.phone_outlined,
                          label: 'Call',
                          onTap: () =>
                              launchUrl(Uri(scheme: 'tel', path: phone)),
                        ),
                    ]),
                  ],
                ]);
          },
        )),
      ]),
    );
  }
}

class _ReviewContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ReviewContactChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.siennaSoft,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.sienna.withValues(alpha: 0.22)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: AppTheme.sienna),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    );
  }
}

class MetricCell extends StatelessWidget {
  final String label, value;
  final bool? positive;
  const MetricCell(this.label, this.value, {this.positive});
  @override
  Widget build(BuildContext context) => Expanded(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(children: [
          Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyle.mono(
                  size: 14,
                  weight: FontWeight.w600,
                  color: positive == null
                      ? AppTheme.ink(context)
                      : positive!
                          ? (AppTheme.isDark(context)
                              ? AppTheme.darkSuccess
                              : AppTheme.success)
                          : (AppTheme.isDark(context)
                              ? AppTheme.darkDanger
                              : AppTheme.danger))),
        ]),
      ));
}

class TabDel extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color color;
  const TabDel({required this.tabBar, required this.color});
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(_, double s, bool __) => Container(color: color, child: tabBar);
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
