import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/animations/app_animations.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/features/admin/lookup/widgets/widgets.dart';
import 'package:fluttertest/features/admin/lookup/services/lookup_service.dart';

export 'package:fluttertest/features/admin/lookup/widgets/lookup_widgets.dart' show FieldDef;

class LookupManagementPage extends StatefulWidget {
  final String title;
  final Future<List<dynamic>> Function() getAll;
  final Future<String> Function(Map<String, String> fields) create;
  final Future<String> Function(int id) delete;
  final List<FieldDef> fields;

  const LookupManagementPage({
    super.key,
    required this.title,
    required this.getAll,
    required this.create,
    required this.delete,
    required this.fields,
  });

  @override
  State<LookupManagementPage> createState() => _LookupManagementPageState();
}

class _LookupManagementPageState extends State<LookupManagementPage>
    with TickerProviderStateMixin, AppAnimationsMixin {

  List<dynamic> _items = [];
  bool _loading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      _controllers[f.key] = TextEditingController();
    }
    initAnimations();
    startAnimations();
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    disposeAnimations();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await widget.getAll();
      if (mounted) setState(() => _items = data);
    } catch (e) {
      if (mounted) _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final values = <String, String>{};
    for (final f in widget.fields) {
      final v = _controllers[f.key]!.text.trim();
      if (v.isEmpty) {
        _snack('Please fill in ${f.label}');
        return;
      }
      values[f.key] = v;
    }
    try {
      await widget.create(values);
      for (final c in _controllers.values) c.clear();
      Navigator.pop(context);
      await _load();
      _snack('Created successfully');
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _delete(int id) async {
    try {
      await widget.delete(id);
      await _load();
      _snack('Deleted');
    } catch (e) {
      if (mounted) _snack(e.toString());
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LookupAddSheet(
        title: widget.title,
        fields: widget.fields,
        controllers: _controllers,
        onCreate: _create,
        isDark: false,
        primary: AppTheme.sienna,
      ),
    );
  }

  void _confirmDelete(int id, String label) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppTheme.surface(context),
        title: Text('delete'.tr,
            style: AppTextStyle.h3(color: AppTheme.ink(context))),
        content: Text(
          'Delete "$label"?',
          style: AppTextStyle.bodySmall(color: AppTheme.muted(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.muted(context))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text('delete'.tr,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  int _itemId(Map<String, dynamic> item) {
    final id = item['id'] ??
        item['benefitId'] ??
        item['inclusionId'] ??
        item['exclusionTypeId'] ??
        item['categoryId'] ??
        item['policyDurationId'] ??
        item['countryId'];
    return id is int ? id : int.tryParse(id?.toString() ?? '') ?? 0;
  }

  String _itemLabel(Map<String, dynamic> item) {
    return (item['title'] ??
            item['name'] ??
            item['categoryName'] ??
            item['label'] ??
            item['countryName'] ??
            'Item')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),

      appBar: AppBar(
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: AppTheme.ink(context)),
        title: Text(widget.title,
            style: AppTextStyle.h3(color: AppTheme.ink(context))),
        actions: [
          GestureDetector(
            onTap: _showAddSheet,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.siennaSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.sienna.withValues(alpha: 0.30)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_rounded, color: AppTheme.sienna, size: 16),
                  const SizedBox(width: 4),
                  Text('Add',
                      style: AppTextStyle.eyebrow(color: AppTheme.sienna)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),

      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.sienna),
            )
          : _items.isEmpty
              ? animatedSection(
                  index: 1,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.siennaBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inbox_outlined,
                            size: 36,
                            color: AppTheme.sienna,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${widget.title} yet',
                          style: AppTextStyle.h3(color: AppTheme.ink(context)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap Add to create one',
                          style: AppTextStyle.bodySmall(
                              color: AppTheme.muted(context)),
                        ),
                      ],
                    ),
                  ),
                )
              : animatedSection(
                  index: 1,
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.sienna,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = _items[i] as Map<String, dynamic>;
                        final id = _itemId(item);
                        final label = _itemLabel(item);
                        return animatedSection(
                          index: (i % 6) + 1,
                          child: LookupItemCard(
                            item: item,
                            primary: AppTheme.sienna,
                            isDark: false,
                            onDelete: () => _confirmDelete(id, label),
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }
}
