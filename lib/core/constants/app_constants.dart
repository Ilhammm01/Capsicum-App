enum ModelVariant {
  fp32,
  int8,
}

/// Path ke assets
class AssetPaths {
  AssetPaths._();

  static const String lottieScan = 'assets/lotties/scan.json';
  static const String modelFp32 = 'assets/models/best.tflite';
  static const String modelInt8 =
      'assets/models/best_capsicum_yolo11n_int8.tflite';

  static String get modelPath =>
      InferenceConfig.activeModel == ModelVariant.int8 ? modelInt8 : modelFp32;

  static const String labelsPath = 'assets/models/labels.txt';
  static const String diseaseInfoPath = 'assets/data/disease_info.json';
}

/// Konstanta model YOLO11n — single source of truth.
/// Urutan classIds HARUS sesuai index output tensor model.
class ModelConstants {
  ModelConstants._();

  /// Jumlah kelas deteksi
  static const int numClasses = 5;

  /// Class IDs berurutan sesuai output tensor [0..4]
  static const List<String> classIds = [
    'bacterial_spot', // 0
    'cercospora_leaf_spot', // 1
    'white_spot', // 2
    'healthy_leaf', // 3
    'curl_virus', // 4
  ];

  /// Nama tampilan (Bahasa Indonesia) per classId
  static const Map<String, String> classDisplayNames = {
    'bacterial_spot': 'Bercak Bakteri',
    'cercospora_leaf_spot': 'Bercak Daun Serkospora',
    'white_spot': 'Bercak Putih',
    'healthy_leaf': 'Daun Sehat',
    'curl_virus': 'Virus Keriting',
  };
}

/// Threshold severity berbasis luas bounding box
class SeverityThresholds {
  SeverityThresholds._();

  /// Di bawah ini = Ringan
  static const double lightMax = 0.15; // 15%
  /// Di bawah ini = Sedang (antara lightMax dan this)
  static const double moderateMax = 0.40; // 40%
  /// Di atas ini = Berat

  static String classify(double ratio) {
    if (ratio < lightMax) return 'Ringan';
    if (ratio < moderateMax) return 'Sedang';
    return 'Berat';
  }
}

/// Konfigurasi inference
class InferenceConfig {
  InferenceConfig._();

  static const ModelVariant activeModel = ModelVariant.fp32;

  /// Ukuran input model (width = height)
  static const int inputSize = 640;

  /// Throttle: minimum interval antar inference (ms).
  /// Membatasi inference agar tidak mengambil seluruh waktu CPU.
  static const int throttleMs = 500;

  /// NMS IoU threshold
  static const double iouThreshold = 0.45;

  /// Confidence threshold minimum untuk dianggap deteksi valid
  static const double confidenceThreshold = 0.25;

  /// Nama Hive box untuk history
  static const String hiveBoxHistory = 'scan_history';
}
