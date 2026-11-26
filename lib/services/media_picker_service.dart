import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class PickedImageFile {
  const PickedImageFile({
    required this.path,
    required this.name,
    this.sizeBytes,
  });

  final String path;
  final String name;
  final int? sizeBytes;
}

class MediaPickerService {
  MediaPickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  Future<PickedImageFile?> pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
    );
    if (picked == null) return null;
    final file = File(picked.path);
    final size = await file.exists() ? await file.length() : null;
    final name = picked.name.isNotEmpty ? picked.name : p.basename(picked.path);
    return PickedImageFile(path: picked.path, name: name, sizeBytes: size);
  }

  Future<PickedImageFile?> pickFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return null;
    final file = File(picked.path);
    final size = await file.exists() ? await file.length() : null;
    final name = picked.name.isNotEmpty ? picked.name : p.basename(picked.path);
    return PickedImageFile(path: picked.path, name: name, sizeBytes: size);
  }

  Future<PickedImageFile?> pickFromFileExplorer() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) return null;

    final name = file.name.isNotEmpty ? file.name : p.basename(path);
    return PickedImageFile(
      path: path,
      name: name,
      sizeBytes: file.size,
    );
  }
}
