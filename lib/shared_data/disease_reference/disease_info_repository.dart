import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

/// Representasi rekomendasi produk per kategori (bahan aktif)
class ProductRecommendation {
  final String category;
  final List<String> activeIngredients;
  final String note;

  const ProductRecommendation({
    required this.category,
    required this.activeIngredients,
    this.note = '',
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      category: json['category'] as String? ?? '',
      activeIngredients: (json['active_ingredients'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      note: json['note'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductRecommendation &&
          runtimeType == other.runtimeType &&
          category == other.category &&
          note == other.note;

  @override
  int get hashCode => category.hashCode ^ note.hashCode;
}

/// Info sumber rekomendasi atau video
class DiseaseSource {
  final String type;
  final String title;
  final String publisher;
  final int year;
  final String url;

  const DiseaseSource({
    required this.type,
    required this.title,
    required this.publisher,
    required this.year,
    required this.url,
  });

  factory DiseaseSource.fromJson(Map<String, dynamic> json) {
    return DiseaseSource(
      type: json['type'] as String? ?? 'unknown',
      title: json['title'] as String? ?? 'Tidak diketahui',
      publisher: json['publisher'] as String? ?? 'Tidak diketahui',
      year: json['year'] as int? ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

/// Info lengkap satu kelas penyakit, sesuai disease_reference_chili_leaf.md
class DiseaseInfo {
  final String id;

  /// Label model (English), e.g. "Cercospora Leaf Spot"
  final String labelModel;

  /// Nama tampilan bahasa Indonesia, e.g. "Bercak Daun Serkospora"
  final String nameId;

  /// Tipe: "healthy" | "disease" | "viral" | "bacterial"
  final String type;

  final String description;
  final List<String> symptoms;
  final List<String> careRecommendations;
  final List<ProductRecommendation> productRecommendations;
  final String warning;
  final List<DiseaseSource> sources;
  final List<DiseaseSource> videoSources;

  const DiseaseInfo({
    required this.id,
    required this.labelModel,
    required this.nameId,
    required this.type,
    required this.description,
    required this.symptoms,
    required this.careRecommendations,
    this.productRecommendations = const [],
    this.warning = '',
    this.sources = const [],
    this.videoSources = const [],
  });

  /// Nama tampilan utama yang digunakan di UI
  String get nama => nameId;

  /// Deskripsi (alias agar widget lama tetap bisa dipakai)
  String get deskripsi => description;

  /// Rekomendasi perawatan (alias agar widget lama tetap bisa dipakai)
  List<String> get rekomendasi => careRecommendations;

  /// Produk rekomendasi (alias untuk kompatibilitas widget lama)
  List<ProductRecommendation> get produk => productRecommendations;

  /// true jika kelas ini adalah kondisi sehat
  bool get isHealthy => type == 'healthy';

  /// true jika penyakit virus (tidak ada obatnya)
  bool get isViral => type == 'viral';

  factory DiseaseInfo.fromJson(Map<String, dynamic> json) {
    return DiseaseInfo(
      id: json['id'] as String,
      labelModel: json['label_model'] as String? ?? '',
      nameId: json['name_id'] as String? ?? json['id'] as String,
      type: json['type'] as String? ?? 'disease',
      description: json['description'] as String? ?? '',
      symptoms: (json['symptoms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      careRecommendations: (json['care_recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      productRecommendations: (json['product_recommendations']
                  as List<dynamic>?)
              ?.map(
                (e) =>
                    ProductRecommendation.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      warning: json['warning'] as String? ?? '',
      sources: (json['sources'] as List<dynamic>?)
              ?.map((e) => DiseaseSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videoSources: (json['video_sources'] as List<dynamic>?)
              ?.map((e) => DiseaseSource.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DiseaseInfoRepository {
  static final DiseaseInfoRepository _instance =
      DiseaseInfoRepository._internal();
  factory DiseaseInfoRepository() => _instance;
  DiseaseInfoRepository._internal();

  Map<String, DiseaseInfo>? _cache;

  /// Load dan cache disease info dari JSON asset
  Future<void> loadIfNeeded() async {
    if (_cache != null) return;

    final jsonStr = await rootBundle.loadString(AssetPaths.diseaseInfoPath);
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    // Schema baru menggunakan key "classes"
    final list = (data['classes'] as List<dynamic>)
        .map((e) => DiseaseInfo.fromJson(e as Map<String, dynamic>))
        .toList();

    _cache = {for (final d in list) d.id: d};
  }

  /// Cari info penyakit berdasarkan ID
  DiseaseInfo? findById(String id) => _cache?[id];

  /// Cari info berdasarkan list ID
  List<DiseaseInfo> findByIds(List<String> ids) {
    return ids.map((id) => _cache?[id]).whereType<DiseaseInfo>().toList();
  }

  /// Semua penyakit/kondisi
  List<DiseaseInfo> getAll() => _cache?.values.toList() ?? [];

  /// Semua kelas yang bukan kondisi sehat
  List<DiseaseInfo> getAllDiseases() =>
      _cache?.values.where((d) => !d.isHealthy).toList() ?? [];
}
