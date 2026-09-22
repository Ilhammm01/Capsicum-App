import 'dart:async';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/detection_result_model.dart';
import '../../data/repositories/yolo_inference_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/location_service.dart';

// =============================================
//  Provider: inference repository (singleton)
// =============================================
final inferenceRepoProvider = Provider<YoloInferenceRepository>((ref) {
  final repo = YoloInferenceRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// =============================================
//  Provider: model loaded state
// =============================================
final modelLoadedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(inferenceRepoProvider);
  return await repo.loadModel();
});

// =============================================
//  Provider: hasil deteksi (detection results)
// =============================================
final detectionResultsProvider = StateProvider<List<DetectionResult>>(
  (ref) => [],
);

// =============================================
//  Provider: camera preview size
// =============================================
final previewSizeProvider = StateProvider<Size?>((ref) => null);

final previewFrameSizeProvider = StateProvider<Size?>((ref) => null);

// =============================================
//  Provider: lokasi saat ini
// =============================================
final currentLocationProvider = StateProvider<Position?>((ref) => null);

final currentLocationNameProvider = StateProvider<String?>((ref) => null);

// =============================================
//  Provider: severity level dari hasil deteksi
// =============================================
final severityLevelProvider = Provider<String>((ref) {
  final results = ref.watch(detectionResultsProvider);
  if (results.isEmpty) return 'Ringan';

  final frameSize = ref.watch(previewFrameSizeProvider);
  final frameW = frameSize?.width.toInt() ?? 1280;
  final frameH = frameSize?.height.toInt() ?? 720;
  final ratio = calculateSeverityRatio(results, frameW, frameH);
  return SeverityThresholds.classify(ratio);
});

// =============================================
//  Provider: average confidence
// =============================================
final avgConfidenceProvider = Provider<double>((ref) {
  final results = ref.watch(detectionResultsProvider);
  if (results.isEmpty) return 0.0;
  return results.map((r) => r.confidence).reduce((a, b) => a + b) /
      results.length;
});

// =============================================
//  Provider: unique disease IDs dari hasil deteksi
// =============================================
final detectedDiseaseIdsProvider = Provider<List<String>>((ref) {
  final results = ref.watch(detectionResultsProvider);
  return results.map((r) => r.classId).toSet().toList();
});

// =============================================
//  Provider: per-disease max confidence
//  Map<classId, maxConfidence>
// =============================================
final perDiseaseConfidenceProvider = Provider<Map<String, double>>((ref) {
  final results = ref.watch(detectionResultsProvider);
  final map = <String, double>{};
  for (final r in results) {
    final current = map[r.classId] ?? 0.0;
    if (r.confidence > current) {
      map[r.classId] = r.confidence;
    }
  }
  return map;
});

// =============================================
//  Provider: jumlah total bounding box per classId
// =============================================
final perDiseaseCountProvider = Provider<Map<String, int>>((ref) {
  final results = ref.watch(detectionResultsProvider);
  final map = <String, int>{};
  for (final r in results) {
    map[r.classId] = (map[r.classId] ?? 0) + 1;
  }
  return map;
});

// =============================================
//  Provider: status lokasi (GPS aktif / tidak)
// =============================================
final locationActiveProvider = StreamProvider.autoDispose<bool>((ref) {
  return Stream.periodic(const Duration(seconds: 2))
      .asyncMap((_) => LocationService.isGpsEnabled())
      .distinct();
});
