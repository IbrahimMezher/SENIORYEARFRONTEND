import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertest/core/services/api_service.dart';
import 'package:fluttertest/core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  final _api = ApiService();
  final _imagePicker = ImagePicker();

  Future<String?> pickAndUpload({
    required String endpoint,
    String accept = 'image/*',
    bool auth = true,
  }) async {
    final wantsPdf = accept.toLowerCase().contains('pdf');
    final picked = wantsPdf ? await _pickFile(wantsPdf: true) : await _pickImage();
    if (picked == null) return null;

    final response = await _api.uploadBytes(
      endpoint,
      bytes: picked.bytes,
      filename: picked.filename,
      auth: auth,
    );
    _api.ensureSuccess(response);
    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return data['url']?.toString();
  }

  Future<_PickedUpload?> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return null;
    if (source == _ImagePickSource.files) return _pickFile(wantsPdf: false);

    final image = await _imagePicker.pickImage(
      source: source == _ImagePickSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    var filename = image.name;
    if (!filename.contains('.')) {
      filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    }
    return _PickedUpload(bytes: bytes, filename: filename);
  }

  Future<_PickedUpload?> _pickFile({required bool wantsPdf}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions:
          wantsPdf ? const ['pdf'] : const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      throw Exception('Could not read selected file.');
    }
    return _PickedUpload(bytes: bytes, filename: picked.name);
  }

  Future<_ImagePickSource?> _chooseImageSource() {
    final context = Get.context;
    if (context == null) return Future.value(_ImagePickSource.files);
    return showModalBottomSheet<_ImagePickSource>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.hair(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Camera',
              onTap: () => Navigator.pop(context, _ImagePickSource.camera),
            ),
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () => Navigator.pop(context, _ImagePickSource.gallery),
            ),
            _SourceTile(
              icon: Icons.folder_open_outlined,
              label: 'Files',
              onTap: () => Navigator.pop(context, _ImagePickSource.files),
            ),
          ]),
        ),
      ),
    );
  }
}

enum _ImagePickSource { camera, gallery, files }

class _PickedUpload {
  final Uint8List bytes;
  final String filename;

  const _PickedUpload({required this.bytes, required this.filename});
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
