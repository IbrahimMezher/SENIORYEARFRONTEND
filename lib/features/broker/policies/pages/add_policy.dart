import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/animations/app_animations.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/core/services/file_upload_service.dart';
import 'package:fluttertest/features/broker/policies/services/policy_service.dart';
import 'package:fluttertest/features/broker/policies/widgets/widgets.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:url_launcher/url_launcher.dart';

class AddPolicyPage extends StatefulWidget {
  final Map<String, dynamic>? existingPolicy;
  const AddPolicyPage({super.key, this.existingPolicy});

  @override
  State<AddPolicyPage> createState() => _AddPolicyPageState();
}

class _AddPolicyPageState extends State<AddPolicyPage>
    with TickerProviderStateMixin, AppAnimationsMixin {
  bool get _isEdit => widget.existingPolicy != null;
  final _service = PolicyService();
  final _uploadService = FileUploadService();
  final _api = ApiService();

  final _policyName = TextEditingController();
  final _description = TextEditingController();
  final _waitingPeriodDays = TextEditingController();
  final _deductiblePerClaim = TextEditingController();
  final _deductiblePerYear = TextEditingController();
  final _maxClaimsPerYear = TextEditingController();
  final _maxClaimAmount = TextEditingController();
  final _minAge = TextEditingController();
  final _maxAge = TextEditingController();
  final _claimProcessingDays = TextEditingController();
  final _documentUrl = TextEditingController();
  final _deliveryPrice = TextEditingController();

  String _status = 'DRAFT';
  final List<Map<String, TextEditingController>> _tiers = [];

  int? _selectedCategoryId;
  String _selectedCategoryName = '';
  int? _selectedDurationId;
  List<int> _selectedExclusionIds = [];
  List<int> _selectedBenefitIds = [];
  List<int> _selectedInclusionIds = [];

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _durations = [];
  List<Map<String, dynamic>> _exclusions = [];
  List<Map<String, dynamic>> _benefits = [];
  List<Map<String, dynamic>> _inclusions = [];
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _categoryFields = [];
  int? _selectedCountryId;

  bool _loading = false;
  bool _loadingCategoryFields = false;
  bool _uploadingDocument = false;

  @override
  void initState() {
    super.initState();
    initAnimations();
    startAnimations();
    _loadDropdowns();
    if (!_isEdit) _addTier();
  }

  @override
  void dispose() {
    for (final c in [
      _policyName,
      _description,
      _waitingPeriodDays,
      _deductiblePerClaim,
      _deductiblePerYear,
      _maxClaimsPerYear,
      _maxClaimAmount,
      _minAge,
      _maxAge,
      _claimProcessingDays,
      _documentUrl,
      _deliveryPrice,
    ]) {
      c.dispose();
    }
    for (final t in _tiers) {
      t.values.forEach((c) => c.dispose());
    }
    disposeAnimations();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Future<void> _uploadPolicyDocument() async {
    if (_uploadingDocument) return;
    setState(() => _uploadingDocument = true);
    try {
      final url = await _uploadService.pickAndUpload(
        endpoint: '/uploads/policy-document',
        accept: 'application/pdf',
      );
      if (url != null && mounted) {
        setState(() => _documentUrl.text = url);
        _snack('PDF uploaded');
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingDocument = false);
    }
  }

  Future<void> _openPolicyDocument() async {
    final url = _api.assetUrl(_documentUrl.text);
    if (url.isEmpty) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
    );
    if (!opened && mounted) _snack('Could not open policy document');
  }

  Future<void> _loadDropdowns() async {
    try {
      final results = await Future.wait([
        _service.getAllCategories(),
        _service.getAllPolicyDurations(),
        _service.getAllExclusionTypes(),
        _service.getAllBenefits(),
        _service.getAllInclusions(),
        _service.getAllCountries(),
      ]);
      setState(() {
        _categories = _map(results[0], 'categoryId', 'categoryName');
        _durations = _map(results[1], 'policyDurationId', 'label');
        _exclusions = _map(results[2], 'exclusionTypeId', 'name');

        _benefits = _map(results[3], 'id', 'title');

        _inclusions = _map(results[4], 'id', 'name');
        _countries = _map(results[5], 'countryId', 'countryName');
        if (_isEdit) _prefPill();
      });
      if (_selectedCategoryId != null) {
        await _loadCategoryFields(_selectedCategoryId);
      }
    } catch (e) {
      _snack('Failed to load form data');
    }
  }

  Future<void> _loadCategoryFields(int? categoryId) async {
    if (categoryId == null) {
      setState(() {
        _categoryFields = [];
        _loadingCategoryFields = false;
      });
      return;
    }
    setState(() => _loadingCategoryFields = true);
    try {
      final raw = await _service.getCategoryFields(categoryId);
      final fields = raw
          .map<Map<String, dynamic>>((f) => {
                'key': f['fieldName']?.toString() ?? '',
                'label': f['fieldLabel']?.toString() ?? '',
                'type': f['fieldType']?.toString() ?? 'text',
                'required': f['isRequired'] == true || f['required'] == true,
              })
          .where((f) =>
              f['key'].toString().isNotEmpty &&
              f['label'].toString().isNotEmpty)
          .toList();
      if (mounted) setState(() => _categoryFields = fields);
    } catch (_) {
      if (mounted) setState(() => _categoryFields = []);
    } finally {
      if (mounted) setState(() => _loadingCategoryFields = false);
    }
  }

  void _prefPill() {
    final p = widget.existingPolicy!;
    _policyName.text = p['policyName']?.toString() ?? '';
    _description.text = p['description']?.toString() ?? '';
    _status = p['status']?.toString() ?? 'DRAFT';
    _waitingPeriodDays.text = p['waitingPeriodDays']?.toString() ?? '';
    _deductiblePerClaim.text = p['deductiblePerClaim']?.toString() ?? '';
    _deductiblePerYear.text = p['deductiblePerYear']?.toString() ?? '';
    _maxClaimsPerYear.text = p['maxClaimsPerYear']?.toString() ?? '';
    _maxClaimAmount.text = p['maxClaimAmount']?.toString() ?? '';
    _minAge.text = p['minAge']?.toString() ?? '';
    _maxAge.text = p['maxAge']?.toString() ?? '';
    _claimProcessingDays.text = p['claimProcessingDays']?.toString() ?? '';
    _documentUrl.text = p['documentUrl']?.toString() ?? '';

    final cat = p['category'];
    if (cat is Map) {
      _selectedCategoryId = _toInt(cat['categoryId']);
      _selectedCategoryName = cat['categoryName']?.toString() ?? '';
    }

    final dur = p['policyDuration'];
    if (dur is Map) _selectedDurationId = _toInt(dur['policyDurationId']);

    _deliveryPrice.text = p['deliveryPrice']?.toString() ?? '';
    final ctry = p['country'];
    if (ctry is Map) _selectedCountryId = _toInt(ctry['countryId']);

    final tiers = p['coverageTiers'] as List? ?? [];
    for (final t in tiers) {
      _tiers.add({
        'tierName':
            TextEditingController(text: t['tierName']?.toString() ?? ''),
        'coverageLimit':
            TextEditingController(text: t['coverageLimit']?.toString() ?? ''),
        'premiumPrice':
            TextEditingController(text: t['premiumPrice']?.toString() ?? ''),
      });
    }
    if (_tiers.isEmpty) _addTier();

    final benefits = p['policyBenefits'] as List? ?? [];
    _selectedBenefitIds = benefits
        .map((b) => _toInt(b['benefit']?['id'] ??
            b['benefit']?['benefitId'] ??
            b['benefitId'] ??
            b['id']))
        .where((id) => id > 0)
        .toList();
    final inclusions = p['policyInclusions'] as List? ?? [];
    _selectedInclusionIds = inclusions
        .map((i) => _toInt(i['inclusion']?['id'] ??
            i['inclusion']?['inclusionId'] ??
            i['inclusionId'] ??
            i['id']))
        .where((id) => id > 0)
        .toList();
    final exclusions = p['policyExclusions'] as List? ?? [];
    _selectedExclusionIds = exclusions
        .map((e) => _toInt(
            e['exclusionType']?['exclusionTypeId'] ?? e['exclusionTypeId']))
        .toList();
  }

  List<Map<String, dynamic>> _map(
    List<dynamic> data,
    String idKey,
    String nameKey,
  ) =>
      data
          .map((e) => {
                'id': _toInt(e[idKey]),
                'name': e[nameKey]?.toString() ?? '',
              })
          .toList();

  void _addTier() => setState(() => _tiers.add({
        'tierName': TextEditingController(),
        'coverageLimit': TextEditingController(),
        'premiumPrice': TextEditingController(),
      }));

  void _removeTier(int i) {
    _tiers[i].values.forEach((c) => c.dispose());
    setState(() => _tiers.removeAt(i));
  }

  Future<void> _submit() async {
    if (_policyName.text.isEmpty ||
        _selectedCategoryId == null ||
        _selectedDurationId == null) {
      _snack('Policy name, category and duration are required');
      return;
    }
    if (_tiers.isEmpty) {
      _snack('Add at least one coverage tier');
      return;
    }
    for (final t in _tiers) {
      if (t.values.any((c) => c.text.isEmpty)) {
        _snack('Fill in all tier fields');
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final tierPayload = _tiers
          .map((t) => {
                'tierName': t['tierName']!.text,
                'coverageLimit': t['coverageLimit']!.text,
                'premiumPrice': t['premiumPrice']!.text,
              })
          .toList();

      if (_isEdit) {
        await _service.editPolicy(
          id: _toInt(widget.existingPolicy!['policyId']),
          updates: {
            'categoryId': _selectedCategoryId,
            'policyName': _policyName.text.trim(),
            'description': _description.text.trim(),
            'policyDurationId': _selectedDurationId,
            'status': _status,
            'exclusionTypeIds': _selectedExclusionIds,
            'benefitIds': _selectedBenefitIds,
            'inclusionIds': _selectedInclusionIds,
            'coverageTiers': tierPayload,
            if (_int(_waitingPeriodDays.text) != null)
              'waitingPeriodDays': _int(_waitingPeriodDays.text),
            if (_deductiblePerClaim.text.isNotEmpty)
              'deductiblePerClaim': _deductiblePerClaim.text,
            if (_deductiblePerYear.text.isNotEmpty)
              'deductiblePerYear': _deductiblePerYear.text,
            if (_int(_maxClaimsPerYear.text) != null)
              'maxClaimsPerYear': _int(_maxClaimsPerYear.text),
            if (_maxClaimAmount.text.isNotEmpty)
              'maxClaimAmount': _maxClaimAmount.text,
            if (_int(_minAge.text) != null) 'minAge': _int(_minAge.text),
            if (_int(_maxAge.text) != null) 'maxAge': _int(_maxAge.text),
            if (_int(_claimProcessingDays.text) != null)
              'claimProcessingDays': _int(_claimProcessingDays.text),
            'documentUrl': _documentUrl.text.trim(),
            if (_selectedCountryId != null) 'countryId': _selectedCountryId,
            if (_deliveryPrice.text.isNotEmpty)
              'deliveryPrice': _deliveryPrice.text,
          },
        );
        if (!mounted) return;
        _snack('Policy updated successfully');
        Navigator.pop(context, true);
      } else {
        await _service.createPolicy(
          categoryId: _selectedCategoryId!,
          policyName: _policyName.text.trim(),
          description: _description.text.trim(),
          policyDurationId: _selectedDurationId!,
          exclusionTypeIds: _selectedExclusionIds,
          benefitIds: _selectedBenefitIds,
          inclusionIds: _selectedInclusionIds,
          coverageTiers: tierPayload,
          status: _status,
          waitingPeriodDays: _int(_waitingPeriodDays.text),
          deductiblePerClaim: _str(_deductiblePerClaim),
          deductiblePerYear: _str(_deductiblePerYear),
          maxClaimsPerYear: _int(_maxClaimsPerYear.text),
          maxClaimAmount: _str(_maxClaimAmount),
          minAge: _int(_minAge.text),
          maxAge: _int(_maxAge.text),
          claimProcessingDays: _int(_claimProcessingDays.text),
          documentUrl: _str(_documentUrl),
          countryId: _selectedCountryId,
          deliveryPrice: _str(_deliveryPrice),
        );
        if (!mounted) return;
        _snack('Policy created successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int? _int(String s) => s.isEmpty ? null : int.tryParse(s);
  String? _str(TextEditingController c) => c.text.isEmpty ? null : c.text;
  int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  List<Map<String, dynamic>> get _extraFields => _categoryFields;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Container(
          color: AppTheme.surface(context),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: AppTheme.screenPad,
              right: AppTheme.screenPad,
              bottom: 16),
          child: Row(children: [
            GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                        color: AppTheme.bg(context),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppTheme.hair(context))),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 15, color: AppTheme.ink(context)))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_isEdit ? 'EDITING' : 'NEW POLICY',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)),
                  Text(_isEdit ? 'Edit Policy' : 'Add New Policy',
                      style: AppTextStyle.h3(color: AppTheme.ink(context))),
                ])),
            if (_loading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppTheme.sienna, strokeWidth: 2))
            else
              GestureDetector(
                  onTap: _submit,
                  child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                          color: AppTheme.sienna,
                          borderRadius:
                              BorderRadius.circular(28)),
                      child: Center(
                          child: Text(_isEdit ? 'Save' : 'Publish',
                              style: AppTextStyle.bodySmall(color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700))))),
          ]),
        )),
        SliverToBoxAdapter(
            child: Divider(height: 1, color: AppTheme.hair(context))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPad, 20, AppTheme.screenPad, 48),
          sliver: SliverToBoxAdapter(
              child: animatedSection(
            index: 1,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SectionTitle(title: 'Basic Info'),
              const SizedBox(height: 12),
              PolicyField(label: 'Policy Name *', controller: _policyName),
              PolicyField(
                  label: 'Description', controller: _description, maxLines: 3),
              PolicyDropdownField(
                label: 'Category *',
                icon: Icons.category_rounded,
                hint: 'Select Category',
                items: _categories,
                selectedId: _selectedCategoryId,
                onChanged: (v) async {
                  final name = v == null
                      ? ''
                      : () {
                          final idx =
                              _categories.indexWhere((c) => c['id'] == v);
                          return idx == -1
                              ? ''
                              : (_categories[idx]['name']?.toString() ?? '');
                        }();
                  setState(() {
                    _selectedCategoryId = v;
                    _selectedCategoryName = name;
                  });
                  await _loadCategoryFields(v);
                },
              ),
              PolicyDropdownField(
                label: 'Policy Duration *',
                icon: Icons.timer_rounded,
                hint: 'Select Duration',
                items: _durations,
                selectedId: _selectedDurationId,
                onChanged: (v) => setState(() => _selectedDurationId = v),
              ),
              PolicyDropdownField(
                label: 'Country *',
                icon: Icons.public_rounded,
                hint: 'Select Country',
                items: _countries,
                selectedId: _selectedCountryId,
                onChanged: (v) => setState(() => _selectedCountryId = v),
              ),
              PolicyField(
                label: 'Delivery Price',
                controller: _deliveryPrice,
                keyboardType: TextInputType.number,
              ),
              if (_loadingCategoryFields || _extraFields.isNotEmpty) ...[
                const SizedBox(height: 4),
                const SectionTitle(title: 'Category-Specific Fields'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.siennaBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.hair(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.info_outline,
                            size: 14, color: AppTheme.sienna),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Customers will fill these fields when purchasing.',
                            style:
                                TextStyle(fontSize: 12, color: AppTheme.sienna),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      if (_loadingCategoryFields)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: AppTheme.sienna,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _extraFields
                              .map((f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: AppTheme.hair(context)),
                                    ),
                                    child: Text(
                                      '${f['label']}${f['required'] == true ? ' *' : ''}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.sienna,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
              const SectionTitle(title: 'Status'),
              const SizedBox(height: 12),
              PolicyStatusSelector(
                value: _status,
                onChanged: (v) => setState(() => _status = v),
              ),
              const SizedBox(height: 16),
              const SectionTitle(title: 'Coverage Tiers *'),
              const SizedBox(height: 12),
              ..._tiers.asMap().entries.map((e) => PolicyTierCard(
                    index: e.key,
                    tierNameCtrl: e.value['tierName']!,
                    coverageLimitCtrl: e.value['coverageLimit']!,
                    premiumPriceCtrl: e.value['premiumPrice']!,
                    onRemove:
                        _tiers.length > 1 ? () => _removeTier(e.key) : null,
                  )),
              TextButton.icon(
                onPressed: _addTier,
                icon: const Icon(Icons.add_circle_outline,
                    color: AppTheme.sienna, size: 18),
                label: Text('add_tier'.tr,
                    style: TextStyle(
                      color: AppTheme.sienna,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              const SizedBox(height: 8),
              const SectionTitle(title: 'Eligibility'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: PolicyField(
                  label: 'Min Age',
                  controller: _minAge,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: PolicyField(
                  label: 'Max Age',
                  controller: _maxAge,
                  keyboardType: TextInputType.number,
                )),
              ]),
              PolicyField(
                label: 'Waiting Period (days)',
                controller: _waitingPeriodDays,
                keyboardType: TextInputType.number,
              ),
              const SectionTitle(title: 'Deductibles'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: PolicyField(
                  label: 'Per Claim',
                  controller: _deductiblePerClaim,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: PolicyField(
                  label: 'Per Year',
                  controller: _deductiblePerYear,
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SectionTitle(title: 'Claim Limits'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: PolicyField(
                  label: 'Max Claims / Year',
                  controller: _maxClaimsPerYear,
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: PolicyField(
                  label: 'Max Claim Amount',
                  controller: _maxClaimAmount,
                  keyboardType: TextInputType.number,
                )),
              ]),
              PolicyField(
                label: 'Claim Processing Days',
                controller: _claimProcessingDays,
                keyboardType: TextInputType.number,
              ),
              const SectionTitle(title: 'Policy Document'),
              const SizedBox(height: 12),
              _PolicyDocumentUploadTile(
                value: _documentUrl.text,
                loading: _uploadingDocument,
                onUpload: _uploadPolicyDocument,
                onView: _openPolicyDocument,
                onClear: () => setState(() => _documentUrl.clear()),
              ),
              const SectionTitle(title: 'Benefits'),
              const SizedBox(height: 12),
              PolicyMultiSelectField(
                items: _benefits,
                selectedIds: _selectedBenefitIds,
                emptyLabel: 'No benefits yet - admin must add them first',
                onChanged: (v) => setState(() => _selectedBenefitIds = v),
              ),
              const SectionTitle(title: 'Inclusions'),
              const SizedBox(height: 12),
              PolicyMultiSelectField(
                items: _inclusions,
                selectedIds: _selectedInclusionIds,
                emptyLabel: 'No inclusions yet - admin must add them first',
                onChanged: (v) => setState(() => _selectedInclusionIds = v),
              ),
              const SectionTitle(title: 'Exclusions'),
              const SizedBox(height: 12),
              PolicyMultiSelectField(
                items: _exclusions,
                selectedIds: _selectedExclusionIds,
                emptyLabel: 'No exclusion types available',
                onChanged: (v) => setState(() => _selectedExclusionIds = v),
              ),
              const SizedBox(height: 28),
            ]),
          )),
        ),
      ]),
    );
  }
}

class _PolicyDocumentUploadTile extends StatelessWidget {
  final String value;
  final bool loading;
  final VoidCallback onUpload;
  final VoidCallback onView;
  final VoidCallback onClear;

  const _PolicyDocumentUploadTile({
    required this.value,
    required this.loading,
    required this.onUpload,
    required this.onView,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = value.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: uploaded ? AppTheme.sienna : AppTheme.hair(context),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.picture_as_pdf_outlined,
            size: 20, color: AppTheme.sienna),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                uploaded ? 'PDF uploaded' : 'Upload PDF document',
                style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                uploaded ? 'Ready for customers to view' : 'Optional',
                style: AppTextStyle.eyebrow(color: AppTheme.muted(context)),
              ),
            ],
          ),
        ),
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.sienna,
            ),
          )
        else ...[
          if (uploaded)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onView,
              icon: const Icon(
                Icons.visibility_outlined,
                size: 18,
                color: AppTheme.sienna,
              ),
            ),
          if (uploaded)
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
              icon: Icon(Icons.close_rounded,
                  size: 18, color: AppTheme.muted(context)),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onUpload,
            icon: Icon(
              uploaded ? Icons.upload_file_outlined : Icons.add_rounded,
              size: 20,
              color: AppTheme.sienna,
            ),
          ),
        ],
      ]),
    );
  }
}
