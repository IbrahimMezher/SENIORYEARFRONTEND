import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class BrokerClaimCard extends StatelessWidget {
  final Map<String, dynamic> claim;
  final VoidCallback onTap;
  final void Function(String status)? onUpdateStatus;
  final String? brokerPhone;
  final String? brokerEmail;

  const BrokerClaimCard({
    super.key,
    required this.claim,
    required this.onTap,
    this.onUpdateStatus,
    this.brokerPhone,
    this.brokerEmail,
  });

  @override
  Widget build(BuildContext context) {
    final status = claim['claimStatus']?.toString() ?? 'PENDING';
    final policyName =
        claim['transaction']?['policy']?['policyName']?.toString() ?? 'Policy';
    final amount = claim['claimAmount']?.toString() ?? '0';
    final date = claim['claimDate']?.toString().split('T').first ?? '';
    final isPending = status == 'PENDING';

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(
              policyName,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          ClaimStatusBadge(status: status),
        ]),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.sienna,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\$$amount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (date.isNotEmpty) Text(date, style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ],
        ),
        if (isPending && onUpdateStatus != null) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.hair(context)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onUpdateStatus!('REJECTED'),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.dangerBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('reject'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger,
                        )),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => onUpdateStatus!('APPROVED'),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppTheme.success.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text('approve'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        )),
                  ),
                ),
              ),
            ),
          ]),
        ],
        if ((brokerPhone != null || brokerEmail != null) && !isPending) ...[
          const SizedBox(height: 10),
          ContactRow(
            phone: brokerPhone,
            email: brokerEmail,
          ),
        ],
      ]),
    );
  }
}

class ClaimStatusBadge extends StatelessWidget {
  final String status;
  const ClaimStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.success;
      case 'REJECTED':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  Color get _bg {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.successBg;
      case 'REJECTED':
        return AppTheme.dangerBg;
      default:
        return AppTheme.warningBg;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _color,
          ),
        ),
      );
}

class ContactRow extends StatelessWidget {
  final String? phone;
  final String? email;

  const ContactRow({
    super.key,
    this.phone,
    this.email,
  });

  Future<void> _launch(String uri) async {
    final u = Uri.parse(uri);
    if (await canLaunchUrl(u)) launchUrl(u);
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (phone != null)
        Expanded(
          child: GestureDetector(
            onTap: () => _launch('tel:$phone'),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.siennaBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.hair(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 14, color: AppTheme.sienna),
                  SizedBox(width: 6),
                  Text('call'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sienna,
                      )),
                ],
              ),
            ),
          ),
        ),
      if (phone != null && email != null) const SizedBox(width: 8),
      if (email != null)
        Expanded(
          child: GestureDetector(
            onTap: () => _launch('mailto:$email'),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.siennaBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.hair(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email_outlined, size: 14, color: AppTheme.sienna),
                  SizedBox(width: 6),
                  Text('email'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.sienna,
                      )),
                ],
              ),
            ),
          ),
        ),
    ]);
  }
}
