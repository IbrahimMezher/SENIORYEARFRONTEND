import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:fluttertest/core/utils/app_textstyles.dart';
import 'package:fluttertest/core/widgets/premium_card.dart';
import 'package:fluttertest/core/widgets/sienna_button.dart';
import 'package:fluttertest/core/widgets/section_title.dart';
import 'package:fluttertest/features/customer/checkout/services/checkout_service.dart';
import 'package:fluttertest/features/customer/checkout/widgets/widgets.dart';
import 'package:fluttertest/features/customer/checkout/services/payment_service.dart';
import 'package:fluttertest/features/customer/checkout/services/address_service.dart';
import 'package:fluttertest/features/customer/browse/services/policy_browse_service.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/services/file_upload_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  final List<dynamic> cartItems;
  final double total;
  final VoidCallback onSuccess;
  const CheckoutPage({
    super.key,
    required this.cartItems,
    required this.total,
    required this.onSuccess,
  });
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _service = PaymentService();
  final _policyService = PolicyBrowseService();
  final _uploadService = FileUploadService();
  final _api = ApiService();
  List<dynamic> _addresses = [];
  int? _selectedAddressId;
  bool _addrsLoading = true;
  bool _showNewForm = false;
  bool _loading = false;

  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController();
  final _addressService = AddressService();
  bool _saveAddress = false;

  final Map<String, TextEditingController> _fieldControllers = {};
  List<Map<String, dynamic>> _activeFields = [];
  bool _fieldsLoading = true;
  String? _uploadingFieldKey;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadCategoryFields();
  }

  Future<void> _loadCategoryFields() async {
    if (widget.cartItems.isEmpty) {
      setState(() => _fieldsLoading = false);
      return;
    }
    final item = widget.cartItems.first as Map<String, dynamic>;
    try {
      int? categoryId = _toIntOrNull(
        item['categoryId'] ??
            item['category']?['categoryId'] ??
            item['policy']?['category']?['categoryId'] ??
            item['policy']?['policyCategory']?['categoryId'] ??
            item['policyCategory']?['categoryId'],
      );

      categoryId ??= await _categoryIdByName(item);
      if (categoryId == null) {
        if (mounted) setState(() => _fieldsLoading = false);
        return;
      }

      final raw = await _policyService.getCategoryFields(categoryId);
      final fields = raw
          .map<Map<String, dynamic>>((f) => {
                'key': f['fieldName']?.toString() ?? '',
                'label': f['fieldLabel']?.toString() ?? '',
                'type': f['fieldType']?.toString() ?? 'text',
                'options': f['fieldOptions']?.toString() ?? '',
                'required': f['isRequired'] == true || f['required'] == true,
              })
          .where((f) =>
              f['key'].toString().isNotEmpty &&
              f['label'].toString().isNotEmpty)
          .toList();

      for (final c in _fieldControllers.values) {
        c.dispose();
      }
      _fieldControllers
        ..clear()
        ..addEntries(fields.map(
            (f) => MapEntry(f['key'].toString(), TextEditingController())));

      if (mounted) {
        setState(() {
          _activeFields = fields;
          _fieldsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fieldsLoading = false);
    }
  }

  Future<int?> _categoryIdByName(Map<String, dynamic> item) async {
    final catName = (item['categoryName'] ??
            item['category']?['categoryName'] ??
            item['policy']?['category']?['categoryName'] ??
            item['policy']?['policyCategory']?['categoryName'] ??
            item['policyCategory']?['categoryName'] ??
            '')
        .toString()
        .toLowerCase();
    if (catName.isEmpty) return null;
    final categories = await _policyService.getAllCategories();
    for (final c in categories) {
      final name = c['categoryName']?.toString().toLowerCase() ?? '';
      if (name == catName || catName.contains(name) || name.contains(catName)) {
        return _toIntOrNull(c['categoryId']);
      }
    }
    return null;
  }

  int? _toIntOrNull(dynamic value) =>
      value is int ? value : int.tryParse(value?.toString() ?? '');

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _phone,
      _street,
      _city,
      _stateCtrl,
      _postal,
      _country
    ]) {
      c.dispose();
    }
    for (final c in _fieldControllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _addrsLoading = true);
    try {
      final data = await _addressService.getMyAddresses();
      if (mounted) {
        setState(() {
          _addresses = data;
          _addrsLoading = false;
          final def = data
              .cast<Map<String, dynamic>>()
              .where((a) => a['isDefault'] == true)
              .toList();
          if (def.isNotEmpty) {
            final id = def.first['addressId'];
            _selectedAddressId = id is int ? id : int.tryParse(id.toString());
          }
          if (data.isEmpty) _showNewForm = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _addrsLoading = false;
          _showNewForm = true;
        });
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppTheme.sienna,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28))));

  String? _buildFieldValues() {
    if (_fieldControllers.isEmpty) return null;
    final map = <String, String>{};
    for (final entry in _fieldControllers.entries) {
      final val = entry.value.text.trim();
      if (val.isNotEmpty) map[entry.key] = val;
    }
    if (map.isEmpty) return null;
    return jsonEncode(map);
  }

  bool _validateCategoryFields() {
    if (_fieldsLoading) {
      _snack('Loading policy details, please wait');
      return false;
    }
    for (final field in _activeFields) {
      if (field['required'] != true) continue;
      final key = field['key'].toString();
      final value = _fieldControllers[key]?.text.trim() ?? '';
      if (value.isEmpty) {
        _snack('${field['label']} is required');
        return false;
      }
    }
    return true;
  }

  TextInputType _keyboardFor(String type) {
    switch (type.toLowerCase()) {
      case 'number':
        return TextInputType.number;
      case 'date':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  List<String> _optionsFor(Map<String, dynamic> field) =>
      (field['options']?.toString() ?? '')
          .split(RegExp(r'[\n,;|]'))
          .map((v) => v.trim())
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList();

  Future<void> _uploadCategoryField(
      String key, String endpoint, String accept) async {
    if (_uploadingFieldKey != null) return;
    setState(() => _uploadingFieldKey = key);
    try {
      final url = await _uploadService.pickAndUpload(
        endpoint: endpoint,
        accept: accept,
      );
      if (url != null && mounted) {
        setState(() => _fieldControllers[key]?.text = url);
        _snack('File uploaded');
      }
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _uploadingFieldKey = null);
    }
  }

  Future<void> _openUploadedField(String? value) async {
    final url = _api.assetUrl(value);
    if (url.isEmpty) return;
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
    );
    if (!opened && mounted) _snack('Could not open uploaded file');
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null && !_showNewForm) {
      _snack('select_add_address'.tr);
      return;
    }
    if (_selectedAddressId == null) {
      if (_street.text.isEmpty || _city.text.isEmpty || _country.text.isEmpty) {
        _snack('fill_street_city_country'.tr);
        return;
      }
      if (_fullName.text.isEmpty || _phone.text.isEmpty) {
        _snack('fill_name_phone'.tr);
        return;
      }
    }
    if (!_validateCategoryFields()) return;
    setState(() => _loading = true);
    try {
      if (_selectedAddressId == null && _saveAddress) {
        await _addressService.addAddress(
            fullName: _fullName.text,
            phoneNumber: _phone.text,
            street: _street.text,
            city: _city.text,
            state: _stateCtrl.text,
            postalCode: _postal.text,
            country: _country.text);
      }
      final result = await _service.checkout(
        paymentMethod: 'CASH',
        fieldValues: _buildFieldValues(),
        addressId: _selectedAddressId,
        street: _selectedAddressId == null ? _street.text : null,
        city: _selectedAddressId == null ? _city.text : null,
        state: _selectedAddressId == null ? _stateCtrl.text : null,
        postalCode: _selectedAddressId == null ? _postal.text : null,
        country: _selectedAddressId == null ? _country.text : null,
      );
      if (!mounted) return;
      widget.onSuccess();
      _showSuccess(result);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(Map<String, dynamic> result) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius)),
              title: Row(children: [
                Icon(Icons.check_circle,
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkSuccess
                        : AppTheme.success,
                    size: 26),
                const SizedBox(width: 10),
                Text('order_placed'.tr,
                    style: AppTextStyle.h3(color: AppTheme.ink(context))),
              ]),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(result['message']?.toString() ?? 'checkout_success'.tr,
                    style:
                        AppTextStyle.bodySmall(color: AppTheme.ink2(context))),
                const SizedBox(height: 12),
                Text('\$${widget.total.toStringAsFixed(2)}',
                    style: AppTextStyle.mono(
                        size: 22,
                        weight: FontWeight.w700,
                        color: AppTheme.sienna)),
                const SizedBox(height: 2),
                Text('incl. 10% VAT',
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
                const SizedBox(height: 4),
                Text('pay_on_delivery'.tr,
                    style:
                        AppTextStyle.eyebrow(color: AppTheme.muted(context))),
              ]),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style:
                        TextButton.styleFrom(foregroundColor: AppTheme.sienna),
                    child: Text('done'.tr,
                        style: TextStyle(fontWeight: FontWeight.w600))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg(context),
      appBar: AppBar(
          backgroundColor: AppTheme.surface(context),
          title: Text('checkout'.tr,
              style: AppTextStyle.h3(color: AppTheme.ink(context))),
          iconTheme: IconThemeData(color: AppTheme.ink(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.screenPad),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionTitle(title: 'order_summary'.tr),
          const SizedBox(height: 10),
          PremiumCard(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                ...widget.cartItems.asMap().entries.map((e) {
                  final item = e.value;
                  final isLast = e.key == widget.cartItems.length - 1;
                  return Column(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(
                                      '${item['policyName']} - ${item['tierName']}',
                                      style: AppTextStyle.bodySmall(
                                          color: AppTheme.ink(context)),
                                      overflow: TextOverflow.ellipsis)),
                              Text('\$${item['premiumPrice']}',
                                  style: AppTextStyle.mono(
                                      size: 13,
                                      weight: FontWeight.w600,
                                      color: AppTheme.ink(context))),
                            ])),
                    if (!isLast)
                      Divider(height: 1, color: AppTheme.hair(context)),
                  ]);
                }),
                Divider(height: 16, color: AppTheme.hairStrong(context)),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('total'.tr,
                          style: AppTextStyle.bodyMedium(
                                  color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('\$${widget.total.toStringAsFixed(2)}',
                          style: AppTextStyle.mono(
                              size: 20,
                              weight: FontWeight.w700,
                              color: AppTheme.sienna)),
                    ]),
              ])),
          const SizedBox(height: AppTheme.sectionGap),
          if (_fieldsLoading || _activeFields.isNotEmpty) ...[
            SectionTitle(title: 'Policy Details'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.siennaSoft,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: AppTheme.sienna.withValues(alpha: 0.2))),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppTheme.sienna),
                const SizedBox(width: 8),
                Flexible(
                    child: Text('broker_review_notice'.tr,
                        style: AppTextStyle.eyebrow(color: AppTheme.sienna))),
              ]),
            ),
            const SizedBox(height: 12),
            if (_fieldsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: AppTheme.sienna),
                ),
              )
            else
              ..._activeFields.map((f) {
                final key = f['key'].toString();
                final required = f['required'] == true;
                final type = f['type']?.toString().toLowerCase() ?? 'text';
                if (type == 'select') {
                  final options = _optionsFor(f);
                  if (options.isNotEmpty) {
                    final current = _fieldControllers[key]?.text.trim() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: options.contains(current) ? current : null,
                        dropdownColor: AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.sienna),
                        items: options
                            .map((option) => DropdownMenuItem(
                                  value: option,
                                  child: Text(option,
                                      style: AppTextStyle.bodySmall(
                                          color: AppTheme.ink(context))),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(
                              () => _fieldControllers[key]?.text = value ?? '');
                        },
                        decoration: InputDecoration(
                          labelText: '${f['label']}${required ? ' *' : ''}',
                          labelStyle: AppTextStyle.eyebrow(
                              color: AppTheme.muted(context)),
                          filled: true,
                          fillColor: AppTheme.isDark(context)
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface2,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                                color: AppTheme.brand, width: 1.5),
                          ),
                        ),
                      ),
                    );
                  }
                }
                if (type == 'image' || type == 'file' || type == 'document') {
                  final isImage = type == 'image';
                  return _CheckoutUploadField(
                    label: '${f['label']}${required ? ' *' : ''}',
                    value: _fieldControllers[key]?.text ?? '',
                    loading: _uploadingFieldKey == key,
                    icon: isImage
                        ? Icons.image_outlined
                        : Icons.picture_as_pdf_outlined,
                    onView: () =>
                        _openUploadedField(_fieldControllers[key]?.text),
                    onClear: () =>
                        setState(() => _fieldControllers[key]?.clear()),
                    onTap: () => _uploadCategoryField(
                      key,
                      isImage
                          ? '/uploads/category-image'
                          : '/uploads/category-document',
                      isImage ? 'image/*' : 'application/pdf',
                    ),
                  );
                }
                return Field(
                  _fieldControllers[key]!,
                  '${f['label']}${required ? ' *' : ''}',
                  keyboard: _keyboardFor(type),
                );
              }),
            const SizedBox(height: AppTheme.sectionGap),
          ],
          SectionTitle(title: 'payment_method'.tr),
          const SizedBox(height: 10),
          PremiumCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: AppTheme.siennaSoft,
                        borderRadius: BorderRadius.circular(28)),
                    child: const Icon(Icons.local_shipping_outlined,
                        color: AppTheme.sienna, size: 18)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('pay_on_delivery'.tr,
                          style: AppTextStyle.bodyMedium(
                                  color: AppTheme.ink(context))
                              .copyWith(fontWeight: FontWeight.w600)),
                      Text('cod_subtitle'.tr,
                          style: AppTextStyle.eyebrow(
                              color: AppTheme.muted(context))),
                    ])),
                Icon(Icons.check_circle,
                    color: AppTheme.isDark(context)
                        ? AppTheme.darkSuccess
                        : AppTheme.success,
                    size: 18),
              ])),
          const SizedBox(height: AppTheme.sectionGap),
          SectionTitle(title: 'delivery_address'.tr),
          const SizedBox(height: 10),
          if (_addrsLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: AppTheme.sienna)))
          else ...[
            ..._addresses.map((addr) {
              final id = addr['addressId'] is int
                  ? addr['addressId'] as int
                  : int.tryParse(addr['addressId'].toString()) ?? 0;
              final sel = _selectedAddressId == id;
              return GestureDetector(
                  onTap: () => setState(() {
                        _selectedAddressId = sel ? null : id;
                        _showNewForm = false;
                      }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.siennaSoft
                            : AppTheme.surface(context),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color:
                                sel ? AppTheme.sienna : AppTheme.hair(context),
                            width: sel ? 1.5 : 1)),
                    child: Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 18,
                          color:
                              sel ? AppTheme.sienna : AppTheme.muted(context)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            if (addr['fullName'] != null)
                              Text(addr['fullName'].toString(),
                                  style: AppTextStyle.bodySmall(
                                          color: AppTheme.ink(context))
                                      .copyWith(fontWeight: FontWeight.w600)),
                            Text(
                                '${addr['street']}, ${addr['city']}, ${addr['country']}',
                                style: AppTextStyle.eyebrow(
                                    color: AppTheme.muted(context))),
                          ])),
                      if (sel)
                        const Icon(Icons.check_circle,
                            color: AppTheme.sienna, size: 18),
                    ]),
                  ));
            }),
            if (_addresses.isNotEmpty)
              GestureDetector(
                  onTap: () => setState(() {
                        _showNewForm = !_showNewForm;
                        if (_showNewForm) _selectedAddressId = null;
                      }),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                          child: Text(
                              _showNewForm
                                  ? 'Use saved address'
                                  : '+ Use different address',
                              style: AppTextStyle.bodySmall(
                                      color: AppTheme.sienna)
                                  .copyWith(fontWeight: FontWeight.w500))))),
            if (_showNewForm) ...[
              Field(_fullName, 'Full Name *'),
              Field(_phone, 'Phone Number *', keyboard: TextInputType.phone),
              Field(_street, 'Street *'),
              Row(children: [
                Expanded(child: Field(_city, 'City *')),
                const SizedBox(width: 12),
                Expanded(child: Field(_stateCtrl, 'State')),
              ]),
              Row(children: [
                Expanded(
                    child: Field(_postal, 'Postal Code',
                        keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: Field(_country, 'Country *')),
              ]),
              GestureDetector(
                  onTap: () => setState(() => _saveAddress = !_saveAddress),
                  child: Row(children: [
                    AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: _saveAddress
                                ? AppTheme.sienna
                                : Colors.transparent,
                            border: Border.all(
                                color: _saveAddress
                                    ? AppTheme.sienna
                                    : AppTheme.hairStrong(context),
                                width: 1.5)),
                        child: _saveAddress
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null),
                    const SizedBox(width: 10),
                    Text('save_address_future'.tr,
                        style: AppTextStyle.bodySmall(
                            color: AppTheme.ink2(context))),
                  ])),
            ],
          ],
          const SizedBox(height: 32),
          SiennaButton(
              label: 'Place Order - \$${widget.total.toStringAsFixed(2)}',
              loading: _loading,
              onTap: _placeOrder),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}

class _CheckoutUploadField extends StatelessWidget {
  final String label;
  final String value;
  final bool loading;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback onView;
  final VoidCallback onClear;

  const _CheckoutUploadField({
    required this.label,
    required this.value,
    required this.loading,
    required this.icon,
    required this.onTap,
    required this.onView,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 6),
          child: Text(label,
              style: AppTextStyle.eyebrow(color: AppTheme.muted(context))),
        ),
        GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.surface(context),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: uploaded ? AppTheme.sienna : AppTheme.hair(context)),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: AppTheme.sienna),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  uploaded ? 'Uploaded' : 'Tap to upload',
                  style: AppTextStyle.bodySmall(color: AppTheme.ink(context))
                      .copyWith(fontWeight: FontWeight.w600),
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
              else if (uploaded) ...[
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'View',
                  onPressed: onView,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                    color: AppTheme.sienna,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Replace',
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.sync_outlined,
                    size: 18,
                    color: AppTheme.sienna,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.muted(context)),
                ),
              ] else
                Icon(
                  Icons.upload_file_outlined,
                  size: 18,
                  color: AppTheme.muted(context),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
