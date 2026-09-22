import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_history_model.dart';
import '../../../../core/constants/app_constants.dart';

class HistoryRepository {
  static Box<ScanHistoryModel>? _box;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScanHistoryModelAdapter());
    _box = await Hive.openBox<ScanHistoryModel>(InferenceConfig.hiveBoxHistory);
  }

  static Box<ScanHistoryModel> get box {
    if (_box == null) throw Exception('HistoryRepository belum diinisialisasi');
    return _box!;
  }

  /// Simpan entry baru ke Hive dan kembalikan key-nya
  static Future<int> addScan(ScanHistoryModel model) async {
    final key = await box.add(model);
    return key;
  }

  /// Ambil semua history, diurutkan dari terbaru
  static List<ScanHistoryModel> getAllScans() {
    final items = box.values.toList();
    items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return items;
  }

  /// Hapus satu entry
  static Future<void> deleteScan(ScanHistoryModel model) async {
    await model.delete();
  }

  /// Hapus semua entry
  static Future<void> clearAll() async {
    await box.clear();
  }

  /// Jumlah total scan tersimpan
  static int get count => box.length;
}
