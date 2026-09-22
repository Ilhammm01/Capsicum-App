import 'package:go_router/go_router.dart';
import '../features/detection/presentation/screens/camera_screen.dart';
import '../features/scan_detail/presentation/screens/scan_detail_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/history/data/models/scan_history_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/scan-detail',
      name: 'scanDetail',
      builder: (context, state) {
        final extra = state.extra as ScanDetailArgs?;
        return ScanDetailScreen(args: extra);
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
);

/// Arguments untuk halaman Scan Detail
class ScanDetailArgs {
  final dynamic historyKey;
  final String imagePath;
  final List<String> detectedDiseaseIds;
  final String severityLevel;
  final double averageConfidence;
  final DateTime scannedAt;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  /// Max confidence per disease classId
  final Map<String, double> diseaseConfidences;

  /// Number of bounding box detections per classId
  final Map<String, int> diseaseDetectionCounts;

  const ScanDetailArgs({
    this.historyKey,
    required this.imagePath,
    required this.detectedDiseaseIds,
    required this.severityLevel,
    required this.averageConfidence,
    required this.scannedAt,
    this.latitude,
    this.longitude,
    this.locationName,
    this.diseaseConfidences = const {},
    this.diseaseDetectionCounts = const {},
  });

  /// Buat dari ScanHistoryModel (history)
  factory ScanDetailArgs.fromHistory(ScanHistoryModel model) {
    return ScanDetailArgs(
      historyKey: model.key,
      imagePath: model.imagePath,
      detectedDiseaseIds: model.detectedDiseaseIds,
      severityLevel: model.severityLevel,
      averageConfidence: model.averageConfidence,
      scannedAt: model.scannedAt,
      latitude: model.latitude,
      longitude: model.longitude,
      locationName: model.locationName,
      diseaseConfidences: model.diseaseConfidences ?? {},
      diseaseDetectionCounts: model.diseaseDetectionCounts ?? {},
    );
  }
}
