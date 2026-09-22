import 'package:hive_flutter/hive_flutter.dart';

part 'scan_history_model.g.dart';

@HiveType(typeId: 0)
class ScanHistoryModel extends HiveObject {
  @HiveField(0)
  late String imagePath;

  @HiveField(1)
  late DateTime scannedAt;

  @HiveField(2)
  late List<String> detectedDiseaseIds;

  @HiveField(3)
  late String severityLevel; // "Ringan" | "Sedang" | "Berat"

  @HiveField(4)
  double? latitude;

  @HiveField(5)
  double? longitude;

  @HiveField(6)
  String? locationName;

  @HiveField(7)
  late double averageConfidence;

  @HiveField(8)
  String? aiRecommendation; // Teks Markdown dari AI recommendation

  @HiveField(9)
  Map<String, double>? diseaseConfidences;

  @HiveField(10)
  Map<String, int>? diseaseDetectionCounts;

  ScanHistoryModel({
    required this.imagePath,
    required this.scannedAt,
    required this.detectedDiseaseIds,
    required this.severityLevel,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.averageConfidence,
    this.aiRecommendation,
    this.diseaseConfidences,
    this.diseaseDetectionCounts,
  });
}
