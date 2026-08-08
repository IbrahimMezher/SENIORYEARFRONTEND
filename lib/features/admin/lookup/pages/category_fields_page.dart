import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/animations/app_animations.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/gradient_button.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/premium_field.dart';
import 'package:fluttertest/features/admin/services/admin_service.dart';
import 'package:fluttertest/features/admin/lookup/services/lookup_service.dart';

class CategoryFieldsPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryFieldsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryFieldsPage> createState() => _CategoryFieldsPageState();
}

class _CategoryFieldsPageState extends State<CategoryFieldsPage>
    with TickerProviderStateMixin, AppAnimationsMixin {
  final _service = LookupService();
  List<dynamic> _fields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    initAnimations();
    startAnimations();
    _load();
  }

  @override
  void dispose() {
    disposeAnimations();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _service.getCategoryFields(widget.categoryId);
      if (mounted) setState(() => _fields = data);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteField(int fieldId) async {
    try {
      await _service.deleteCategoryField(widget.categoryId, fieldId);
      await _load();
      _snack('Field deleted');
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.sienna,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

  void _showAddField() {
    final labelCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final optionsCtrl = TextEditingController();
    String selectedType = 'text';
    bool isRequired = true;
    bool adding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                              color: AppTheme.hair(context),
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
                    Text('add_custom_field'.tr,
                        style: AppTextStyle.h3(color: AppTheme.ink(context))),
                  ]),
                  const SizedBox(height: 20),
                  PremiumField(
                    controller: labelCtrl,
                    label: 'Field Label (shown to customer)',
                    hint: 'e.g. Vehicle Make',
                    prefixIcon: Icons.label_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  PremiumField(
                    controller: nameCtrl,
                    label: 'Field Key',
                    hint: 'e.g. vehicleMake',
                    prefixIcon: Icons.vpn_key_outlined,
                  ),
                  const SizedBox(height: 16),
                  Text('field_type'.tr,
                      style: AppTextStyle.eyebrow(
                          color: AppTheme.muted(context))),
                  const SizedBox(height: 8),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['text', 'number', 'date', 'image', 'select']
                          .map((type) => GestureDetector(
                                onTap: () => setS(() => selectedType = type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedType == type
                                        ? AppTheme.sienna
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: selectedType == type
                                            ? AppTheme.sienna
                                            : AppTheme.hair(context)),
                                  ),
                                  child: Text(
                                      type.substring(0, 1).toUpperCase() +
                                          type.substring(1),
                                      style: AppTextStyle.eyebrow(
                                              color: selectedType == type
                                                  ? Colors.white
                                                  : AppTheme.ink(context))
                                          .copyWith(
                                              fontWeight: FontWeight.w700)),
                                ),
                              ))
                          .toList()),
                  if (selectedType == 'select') ...[
                    const SizedBox(height: 12),
                    PremiumField(
                      controller: optionsCtrl,
                      label: 'Options (comma or new line separated)',
                      hint: 'Option A, Option B, Option C',
                      prefixIcon: Icons.list_alt_outlined,
                      maxLines: 3,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('required_field'.tr,
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.ink(context))),
                    value: isRequired,
                    onChanged: (v) => setS(() => isRequired = v),
                    activeColor: AppTheme.sienna,
                  ),
                  const SizedBox(height: 12),
                  GradientButton(
                    label: 'Add Field',
                    loading: adding,
                    onTap: () async {
                      if (labelCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                        _snack('Fill in label and key');
                        return;
                      }
                      if (selectedType == 'select' &&
                          _parseOptions(optionsCtrl.text).length < 2) {
                        _snack('Add at least two select options');
                        return;
                      }
                      setS(() => adding = true);
                      try {
                        await _service.addCategoryField(
                          categoryId: widget.categoryId,
                          fieldName: nameCtrl.text.trim().replaceAll(' ', '_'),
                          fieldLabel: labelCtrl.text.trim(),
                          fieldType: selectedType,
                          isRequired: isRequired,
                          fieldOptions: selectedType == 'select'
                              ? _parseOptions(optionsCtrl.text).join('\n')
                              : null,
                        );
                        if (mounted) {
                          Navigator.pop(ctx);
                          await _load();
                          _snack('Field added!');
                        }
                      } catch (e) {
                        setS(() => adding = false);
                        _snack(e.toString().replaceFirst('Exception: ', ''));
                      }
                    },
                  ),
                ]),
          ),
        ),
      ),
    );
  }

  List<String> _parseOptions(String raw) => raw
      .split(RegExp(r'[\n,;|]'))
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppTheme.ink(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('custom_fields'.tr,
              style: AppTextStyle.h3(color: AppTheme.ink(context))),
          Text(widget.categoryName,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ]),
        actions: [
          GestureDetector(
            onTap: _showAddField,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.sienna.withValues(alpha: 0.30))),
              child: Row(children: [
                const Icon(Icons.add_rounded, color: AppTheme.sienna, size: 16),
                const SizedBox(width: 4),
                Text('add'.tr,
                    style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                        .copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.sienna))
          : _fields.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: AppTheme.siennaBg, shape: BoxShape.circle),
                      child: const Icon(Icons.tune_outlined,
                          size: 36, color: AppTheme.sienna)),
                  const SizedBox(height: 16),
                  Text('no_custom_fields'.tr,
                      style: AppTextStyle.h3(color: AppTheme.ink(context))),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                        'add_fields_hint'
                            .trParams({'category': widget.categoryName}),
                        textAlign: TextAlign.center,
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.muted(context))),
                  ),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.sienna,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fields.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final f = _fields[i] as Map<String, dynamic>;
                      final fid = f['id'] is int
                          ? f['id'] as int
                          : int.tryParse(f['id'].toString()) ?? 0;
                      return animatedSection(
                        index: (i % 6) + 1,
                        child: PremiumCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(children: [
                            Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: AppTheme.siennaBg,
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(
                                    _typeIcon(
                                        f['fieldType']?.toString() ?? 'text'),
                                    size: 18,
                                    color: AppTheme.sienna)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(f['fieldLabel']?.toString() ?? '',
                                      style: AppTextStyle.bodySmall(
                                              color: AppTheme.ink(context))
                                          .copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    _typeBadge(
                                        f['fieldType']?.toString() ?? 'text'),
                                    const SizedBox(width: 6),
                                    if (f['isRequired'] == true ||
                                        f['required'] == true)
                                      Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                              color: AppTheme.dangerBg,
                                              borderRadius:
                                                  BorderRadius.circular(14)),
                                          child: Text('required'.tr,
                                              style: AppTextStyle.eyebrow(
                                                      color: AppTheme.danger)
                                                  .copyWith(fontSize: 9))),
                                  ]),
                                  if ((f['fieldOptions']?.toString() ?? '')
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 3),
                                      child: Text(
                                          'options: ${_parseOptions(f['fieldOptions'].toString()).join(', ')}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTextStyle.eyebrow(
                                              color: AppTheme.muted(context))),
                                    ),
                                  Text('key: ${f['fieldName']}',
                                      style: AppTextStyle.eyebrow(
                                          color: AppTheme.muted(context))),
                                ])),
                            GestureDetector(
                              onTap: () => _confirmDelete(
                                  fid, f['fieldLabel']?.toString() ?? ''),
                              child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                      color: AppTheme.dangerBg,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: const Icon(Icons.delete_outline,
                                      size: 16, color: AppTheme.danger)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'number':  return Icons.numbers;
      case 'date':    return Icons.calendar_today_outlined;
      case 'image':   return Icons.image_outlined;
      case 'select':  return Icons.list_alt_outlined;
      default:        return Icons.text_fields;
    }
  }

  Widget _typeBadge(String type) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
            color: AppTheme.siennaBg, borderRadius: BorderRadius.circular(14)),
        child: Text(type,
            style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                .copyWith(fontSize: 9, fontWeight: FontWeight.w700)),
      );

  void _confirmDelete(int fid, String label) {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              backgroundColor: AppTheme.surface(context),
              title: Text('delete_field'.tr,
                  style: AppTextStyle.h3(color: AppTheme.ink(context))),
              content: Text(
                  'delete_field_confirm'.trParams({'label': label}),
                  style: AppTextStyle.bodySmall(color: AppTheme.muted(context))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('cancel'.tr,
                        style: TextStyle(color: AppTheme.muted(context)))),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteField(fid);
                    },
                    style:
                        TextButton.styleFrom(foregroundColor: AppTheme.danger),
                    child: Text('delete'.tr,
                        style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
            ));
  }
}
