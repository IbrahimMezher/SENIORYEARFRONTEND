import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/monogram.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/features/admin/brokers/services/broker_admin_service.dart';

class SummaryCell extends StatelessWidget {
  final String value, label;
  final Color color;
  const SummaryCell(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(context),
        child: Column(children: [
          Text(value,
              style: AppTextStyle.mono(
                  size: 28,
                  weight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ]),
      );
}

class BrokerRequestCard extends StatefulWidget {
  final Map<String, dynamic> user;
  final String Function(String?) timeAgo;
  final VoidCallback onApprove, onReject;
  final BrokerAdminService adminService;

  const BrokerRequestCard({
    required this.user,
    required this.timeAgo,
    required this.onApprove,
    required this.onReject,
    required this.adminService,
  });

  @override
  State<BrokerRequestCard> createState() => BrokerRequestCardState();
}

class BrokerRequestCardState extends State<BrokerRequestCard> {
  final _api = ApiService();
  Map<String, dynamic>? _details;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final uid = widget.user['userId'];
    if (uid == null) {
      setState(() => _loadingDetails = false);
      return;
    }
    final userId = uid is int ? uid : int.tryParse(uid.toString()) ?? 0;
    try {
      final d = await widget.adminService.getBrokerDetails(userId);
      if (mounted)
        setState(() {
          _details = d;
          _loadingDetails = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  String _assetUrl(String? value) {
    final path = value?.trim() ?? '';
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = _api.baseUrl.endsWith('/')
        ? _api.baseUrl.substring(0, _api.baseUrl.length - 1)
        : _api.baseUrl;
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  Future<void> _openUploadedFile(String? value) async {
    final url = _assetUrl(value);
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _openImagePreview(BuildContext context, String title, String? value) {
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
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 42, color: AppTheme.muted(context)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: GestureDetector(
                onTap: () => _openUploadedFile(value),
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

  @override
  Widget build(BuildContext context) {
    final name = widget.user['fullName']?.toString() ?? 'Broker';
    final date = widget.user['createdAt']?.toString();
    final country = widget.user['country']?['countryName']?.toString() ??
        _details?['country']?['countryName']?.toString() ??
        '—';
    final company = _details?['broker']?['companyName']?.toString() ??
        _details?['companyName']?.toString() ??
        widget.user['companyName']?.toString() ??
        '—';
    final license = _details?['broker']?['licenseNumber']?.toString() ??
        _details?['licenseNumber']?.toString() ??
        '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Monogram(name: name, size: 44, fontSize: 15),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: AppTextStyle.bodyMedium(color: AppTheme.ink(context))
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(company,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ])),
          Text(widget.timeAgo(date),
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ]),
        const SizedBox(height: 12),
        if (_loadingDetails)
          Row(children: [
            SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppTheme.sienna)),
            const SizedBox(width: 8),
            Text('loading_details'.tr,
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
          ])
        else
          Row(children: [
            Expanded(child: InfoCell('LICENSE', license)),
            Expanded(child: InfoCell('COUNTRY', country)),
          ]),
        const SizedBox(height: 10),
        SiennaButton(
          label: 'view_full_details'.tr,
          icon: Icons.visibility_outlined,
          height: 40,
          ghost: true,
          onTap: () => _showFullDetails(context, name, company, license, country),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: SiennaButton(
              label: 'reject'.tr,
              icon: Icons.close_rounded,
              height: 46,
              variant: AppButtonVariant.secondary,
              onTap: widget.onReject,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SiennaButton(
              label: 'approve'.tr,
              icon: Icons.check_rounded,
              height: 46,
              onTap: widget.onApprove,
            ),
          ),
        ]),
      ]),
    );
  }

  void _showFullDetails(BuildContext context, String name, String company,
      String license, String country) {
    final d = _details ?? {};
    final bd = (d['broker'] as Map?) ?? const {};
    final logoUrl = bd['logoUrl']?.toString() ?? d['logoUrl']?.toString();
    final idFrontUrl =
        bd['idFrontUrl']?.toString() ?? d['idFrontUrl']?.toString();
    final idBackUrl = bd['idBackUrl']?.toString() ?? d['idBackUrl']?.toString();
    final email =
        widget.user['email']?.toString() ?? d['email']?.toString() ?? '—';
    final phone = widget.user['phoneNumber']?.toString() ??
        d['phoneNumber']?.toString() ??
        '—';
    final emailVerified = (d['emailVerified'] == true) ? 'Yes' : 'No';
    final phoneVerified = (d['phoneVerified'] == true) ? 'Yes' : 'No';
    final address =
        bd['address']?.toString() ?? d['address']?.toString() ?? '—';
    final website =
        bd['websiteUrl']?.toString() ?? d['websiteUrl']?.toString() ?? '—';
    final taxId = bd['taxId']?.toString() ?? d['taxId']?.toString() ?? '—';
    final username = d['username']?.toString() ?? '—';
    final role = d['role']?.toString() ?? '—';
    final status =
        widget.user['status']?.toString() ?? d['status']?.toString() ?? '—';
    final createdAt = widget.user['createdAt']?.toString().split('T').first ??
        d['createdAt']?.toString().split('T').first ??
        '—';
    final userId =
        widget.user['userId']?.toString() ?? d['userId']?.toString() ?? '—';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusLg)),
          ),
          child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
                  Monogram(name: name, size: 52, fontSize: 18),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(name,
                            style:
                                AppTextStyle.h3(color: AppTheme.ink(context))),
                        if (company.isNotEmpty)
                          Text(company,
                              style: AppTextStyle.eyebrow(
                                  color: AppTheme.muted(context))),
                      ])),
                ]),
                const SizedBox(height: 20),
                DetailSection('IDENTITY', {
                  'User ID': userId,
                  'Username': username,
                  'Role': role,
                  'Status': status,
                  'Registered': createdAt
                }),
                DetailSection('CONTACT', {
                  'Email': email,
                  'Email Verified': emailVerified,
                  'Phone': phone,
                  'Phone Verified': phoneVerified
                }),
                DetailSection('COMPANY', {
                  'Company': company,
                  'License': license,
                  'Tax ID': taxId,
                  'Address': address,
                  'Website': website
                }),
                DetailSection('LOCATION', {'Country': country}),
                if (_assetUrl(logoUrl).isNotEmpty ||
                    _assetUrl(idFrontUrl).isNotEmpty ||
                    _assetUrl(idBackUrl).isNotEmpty) ...[
                  Text('DOCUMENTS',
                      style:
                          AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.cardDecoration(context),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_assetUrl(logoUrl).isNotEmpty) ...[
                            GestureDetector(
                              onTap: () => _openImagePreview(
                                  context, 'Company Logo', logoUrl),
                              child: Stack(children: [
                                ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(28),
                                  child: Image.network(
                                    _assetUrl(logoUrl),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Icon(Icons.open_in_full,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ]),
                            ),
                            const SizedBox(height: 10),
                          ],
                          Row(children: [
                            Expanded(
                                child: _DocumentButton(
                              label: 'ID Front',
                              enabled: _assetUrl(idFrontUrl).isNotEmpty,
                              onTap: () => _openImagePreview(
                                  context, 'ID Front', idFrontUrl),
                            )),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _DocumentButton(
                              label: 'ID Back',
                              enabled: _assetUrl(idBackUrl).isNotEmpty,
                              onTap: () => _openImagePreview(
                                  context, 'ID Back', idBackUrl),
                            )),
                          ]),
                        ]),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: SiennaButton(
                      label: 'reject'.tr,
                      icon: Icons.close_rounded,
                      variant: AppButtonVariant.secondary,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onReject();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SiennaButton(
                      label: 'approve'.tr,
                      icon: Icons.check_rounded,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onApprove();
                      },
                    ),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }
}

class _DocumentButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _DocumentButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.accentSoft(context) : AppTheme.bg(context),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.hair(context)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(
            Icons.open_in_new,
            size: 14,
            color: enabled ? AppTheme.sienna : AppTheme.muted(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyle.eyebrow(
              color: enabled ? AppTheme.sienna : AppTheme.muted(context),
            ),
          ),
        ]),
      ),
    );
  }
}

class DetailSection extends StatelessWidget {
  final String title;
  final Map<String, String> data;
  const DetailSection(this.title, this.data);

  @override
  Widget build(BuildContext context) {
    final filtered = Map.fromEntries(
        data.entries.where((e) => e.value.isNotEmpty && e.value != '—'));
    if (filtered.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.cardDecoration(context),
          child: Column(
              children: filtered.entries.map((e) {
            final isLast = e.key == filtered.keys.last;
            return Column(children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(children: [
                  Text(e.key,
                      style: AppTextStyle.bodySmall(
                          color: AppTheme.muted(context))),
                  const Spacer(),
                  Flexible(
                      child: Text(e.value,
                          textAlign: TextAlign.end,
                          style: AppTextStyle.bodySmall(
                                  color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                ]),
              ),
              if (!isLast) Divider(height: 1, color: AppTheme.hair(context)),
            ]);
          }).toList()),
        ),
      ]),
    );
  }
}

class InfoCell extends StatelessWidget {
  final String label, value;
  const InfoCell(this.label, this.value);

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        const SizedBox(height: 2),
        Text(value,
            style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                .copyWith(fontWeight: FontWeight.w600)),
      ]);
}
