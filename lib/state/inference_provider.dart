import 'package:flutter/foundation.dart';

import 'package:ovision_app/core/errors/api_exception.dart';
import 'package:ovision_app/models/inference_record.dart';
import 'package:ovision_app/repositories/inference_repository.dart';
import 'package:ovision_app/services/media_picker_service.dart';

class InferenceProvider extends ChangeNotifier {
  InferenceProvider({required InferenceRepository repository}) : _repository = repository;

  final InferenceRepository _repository;

  PickedImageFile? _selectedImage;
  bool _isUploading = false;
  double? _uploadProgress;
  String? _uploadError;
  InferenceRecord? _lastResult;

  List<InferenceRecord> _history = const [];
  bool _isLoadingHistory = false;
  String? _historyError;

  PickedImageFile? get selectedImage => _selectedImage;
  bool get isUploading => _isUploading;
  double? get uploadProgress => _uploadProgress;
  String? get uploadError => _uploadError;
  InferenceRecord? get lastResult => _lastResult;

  List<InferenceRecord> get history => _history;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get historyError => _historyError;

  void setSelectedImage(PickedImageFile image) {
    _selectedImage = image;
    _uploadError = null;
    notifyListeners();
  }

  void clearSelection() {
    _selectedImage = null;
    _uploadError = null;
    _uploadProgress = null;
    notifyListeners();
  }

  Future<InferenceRecord?> submitInference({
    double? distanceCm,
    double? confThreshold,
    int? imgsz,
  }) async {
    final image = _selectedImage;
    if (image == null) {
      _uploadError = 'Selecione ou tire uma foto do animal antes de enviar.';
      notifyListeners();
      return null;
    }

    _isUploading = true;
    _uploadProgress = 0.0;
    _uploadError = null;
    notifyListeners();

    try {
      final created = await _repository.createInference(
        filePath: image.path,
        filename: image.name,
        distanceCm: distanceCm,
        confThreshold: confThreshold,
        imgsz: imgsz,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
        },
      );
      _lastResult = created;
      _history = [created, ..._history.where((item) => item.id != created.id)];
      return created;
    } on ApiException catch (e) {
      _uploadError = e.message;
      return null;
    } finally {
      _isUploading = false;
      _uploadProgress = null;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      final response = await _repository.listInferences();
      _history = response.results;
    } on ApiException catch (e) {
      _historyError = e.message;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<InferenceRecord?> fetchDetail(String id) async {
    try {
      final detail = await _repository.getInferenceDetail(id);
      _history = [
        for (final item in _history)
          if (item.id == detail.id) detail else item,
      ];
      notifyListeners();
      return detail;
    } on ApiException {
      return null;
    }
  }

  void reset() {
    _selectedImage = null;
    _isUploading = false;
    _uploadProgress = null;
    _uploadError = null;
    _lastResult = null;
    _history = const [];
    _isLoadingHistory = false;
    _historyError = null;
    notifyListeners();
  }
}
