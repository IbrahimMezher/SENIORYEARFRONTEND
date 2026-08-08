import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';

class CustomerTransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const CustomerTransactionCard({
    super.key,
    required this.transaction,
  });

  Future<void> _launch(String uri) async {
    final u = Uri.parse(uri);
    if (await canLaunchUrl(u)) launchUrl(u);
  }

  Color _deliveryColor(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED':
        return AppTheme.success;
      case 'REJECTED':
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }

  Color _deliveryBg(String s) {
    switch (s.toUpperCase()) {
      case 'COMPLETED':
        return AppTheme.successBg;
      case 'REJECTED':
        return AppTheme.dangerBg;
      default:
        return AppTheme.warningBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final policyName =
        transaction['policy']?['policyName']?.toString() ?? 'Policy';
    final amount = transaction['amountPaid']?.toString() ?? '0';
    final delivery = transaction['deliveryStatus']?.toString() ?? 'PENDING';
    final isRejected = delivery.toUpperCase() == 'REJECTED';
    final brokerUser = transaction['policy']?['broker']?['user'];
    final brokerPhone = brokerUser?['phoneNumber']?.toString();
    final brokerEmail = brokerUser?['email']?.toString();

    return PremiumCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(
              policyName,
              style: AppTextStyle.bodySmall(color: AppTheme.ink(context)).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _deliveryBg(delivery),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              delivery,
              style: AppTextStyle.eyebrow(color: _deliveryColor(delivery)).copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.sienna,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '\$$amount',
            style: AppTextStyle.mono(size: 11, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
        if (isRejected && (brokerPhone != null || brokerEmail != null)) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: AppTheme.hair(context)),
          const SizedBox(height: 10),
          Text(
            'Policy rejected — contact broker to dispute',
            style: AppTextStyle.bodySmall(color: AppTheme.danger).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(children: [
            if (brokerPhone != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launch('tel:$brokerPhone'),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.siennaBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.hair(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.sienna),
                        SizedBox(width: 4),
                        Text('call'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sienna,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            if (brokerPhone != null && brokerEmail != null)
              const SizedBox(width: 8),
            if (brokerEmail != null)
              Expanded(
                child: GestureDetector(
                  onTap: () => _launch('mailto:$brokerEmail'),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.siennaBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.hair(context)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email_outlined,
                            size: 14, color: AppTheme.sienna),
                        SizedBox(width: 4),
                        Text('email'.tr,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.sienna,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}
