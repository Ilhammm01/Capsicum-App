import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/app_constants.dart';

/// Pilihan karakter suara
enum TtsVoiceType {
  female('Suara Wanita (Ramah & Natural)'),
  male('Suara Pria (Berwibawa & Tenang)'),
  neutral('Suara Netral / Bawaan');

  final String label;
  const TtsVoiceType(this.label);
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(() {
    service.stop();
  });
  return service;
});

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal() {
    _initTts();
  }

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // Default saat ini adalah Suara Wanita yang jelas dan ramah
  TtsVoiceType _currentVoiceType = TtsVoiceType.female;
  TtsVoiceType get currentVoiceType => _currentVoiceType;

  Future<void> _initTts() async {
    if (_isInitialized) return;
    try {
      // Set bahasa Indonesia
      final isAvailable = await _flutterTts.isLanguageAvailable('id-ID');
      if (isAvailable == true) {
        await _flutterTts.setLanguage('id-ID');
      } else {
        await _flutterTts.setLanguage('id');
      }

      await _flutterTts.setVolume(1.0);
      await _flutterTts.awaitSynthCompletion(true);
      _isInitialized = true;

      // Terapkan karakter suara wanita default
      await _applyVoiceSettings();
    } catch (e) {
      debugPrint('[TtsService] Inisialisasi gagal: $e');
    }
  }

  /// Ubah karakter suara (Wanita, Pria, atau Netral)
  Future<void> setVoiceType(TtsVoiceType type) async {
    _currentVoiceType = type;
    await _applyVoiceSettings();
    debugPrint('[TtsService] Karakter suara diubah ke: ${type.label}');
  }

  /// Menerapkan profil suara, pitch, dan tempo secara konsisten
  Future<void> _applyVoiceSettings() async {
    try {
      // 1. Cari profil suara yang sesuai di engine TTS perangkat
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        final idVoices = <Map<String, String>>[];
        for (final v in voices) {
          if (v is Map) {
            final locale = (v['locale'] ?? '').toString();
            final name = (v['name'] ?? '').toString();
            final features = (v['features'] ?? '').toString();
            if (locale.toLowerCase().contains('id')) {
              idVoices.add({
                'name': name,
                'locale': locale,
                'features': features,
              });
            }
          }
        }

        Map<String, String>? targetVoice;
        if (_currentVoiceType == TtsVoiceType.female) {
          // 1. Suara Wanita: Pada Google TTS Android, 'id-id-x-dfz' (Suara 1) adalah profil suara wanita
          for (final v in idVoices) {
            final name = v['name']!.toLowerCase();
            final feat = v['features']!.toLowerCase();
            if (name.contains('female') ||
                feat.contains('female') ||
                name.contains('dfz')) {
              targetVoice = {'name': v['name']!, 'locale': v['locale']!};
              break;
            }
          }
          // Default: suara pertama pada daftar bahasa Indonesia (wanita di Google TTS)
          targetVoice ??= idVoices.isNotEmpty
              ? {'name': idVoices.first['name']!, 'locale': idVoices.first['locale']!}
              : null;
        } else if (_currentVoiceType == TtsVoiceType.male) {
          // 2. Suara Pria: Pada Google TTS Android, profil pria adalah suara selain dfz (Suara 2)
          for (final v in idVoices) {
            final name = v['name']!.toLowerCase();
            final feat = v['features']!.toLowerCase();
            if (name.contains('male') ||
                feat.contains('male') ||
                (!name.contains('dfz') && idVoices.length > 1)) {
              targetVoice = {'name': v['name']!, 'locale': v['locale']!};
              break;
            }
          }
          // Jika tidak ada keyword male, pilih suara kedua (profil pria) jika ada
          if (targetVoice == null && idVoices.length > 1) {
            final alt = idVoices.firstWhere(
              (v) => !v['name']!.toLowerCase().contains('dfz'),
              orElse: () => idVoices[1],
            );
            targetVoice = {'name': alt['name']!, 'locale': alt['locale']!};
          }
        }

        if (targetVoice != null && targetVoice.isNotEmpty) {
          await _flutterTts.setVoice(targetVoice);
        }
      }

      // 2. Modulasi Pitch dan Tempo:
      // - Suara Wanita: nada cerah dan alami (pitch: 1.05, speed: 0.48)
      // - Suara Pria: nada lebih berat/rendah dan tenang (pitch: 0.88, speed: 0.46)
      switch (_currentVoiceType) {
        case TtsVoiceType.female:
          await _flutterTts.setPitch(1.05);
          await _flutterTts.setSpeechRate(0.48);
          break;
        case TtsVoiceType.male:
          await _flutterTts.setPitch(0.88);
          await _flutterTts.setSpeechRate(0.46);
          break;
        case TtsVoiceType.neutral:
          await _flutterTts.setPitch(1.0);
          await _flutterTts.setSpeechRate(0.5);
          break;
      }
    } catch (e) {
      debugPrint('[TtsService] _applyVoiceSettings error: $e');
    }
  }

  /// Putar contoh suara untuk pengujian
  Future<void> playSample(TtsVoiceType type) async {
    _currentVoiceType = type;
    final sampleText = type == TtsVoiceType.female
        ? 'Halo, ini adalah contoh suara wanita untuk aplikasi Capsicum.'
        : type == TtsVoiceType.male
            ? 'Halo, ini adalah contoh suara pria untuk aplikasi Capsicum.'
            : 'Halo, ini adalah contoh suara netral bawaan sistem.';
    await speak(sampleText);
  }

  /// Hentikan suara yang sedang berbicara
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('[TtsService] Gagal stop: $e');
    }
  }

  /// Ucapkan teks bebas dalam bahasa Indonesia
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await _initTts();
      // Pastikan pengaturan pitch & voice selalu diterapkan sebelum setiap kali berbicara
      await _applyVoiceSettings();
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('[TtsService] Gagal speak: $e');
    }
  }

  /// Ucapkan hasil deteksi scan secara terstruktur dan alami,
  /// termasuk tingkat confidence (keyakinan) dan seluruh penyakit yang terdeteksi.
  Future<void> speakDetectionResult({
    required List<String> diseaseIds,
    String? severityLevel,
    Map<String, double>? diseaseConfidences,
    double? averageConfidence,
  }) async {
    // 1. Jika tidak ada deteksi sama sekali
    if (diseaseIds.isEmpty) {
      await speak('Tidak ada penyakit yang terdeteksi pada tanaman cabai.');
      return;
    }

    // 2. Pisahkan jika hanya daun sehat
    final diseases = diseaseIds.where((id) => id != 'healthy_leaf').toList();
    if (diseases.isEmpty) {
      String msg =
          'Tanaman cabai dalam kondisi sehat. Tidak terdeteksi gejala penyakit.';
      final healthyConf =
          diseaseConfidences?['healthy_leaf'] ?? averageConfidence;
      if (healthyConf != null && healthyConf > 0) {
        final pct = healthyConf <= 1.0
            ? (healthyConf * 100).round()
            : healthyConf.round();
        msg =
            'Tanaman cabai dalam kondisi sehat, dengan tingkat keyakinan $pct persen.';
      }
      await speak(msg);
      return;
    }

    // Helper untuk format confidence ke persen
    String getConfText(String classId) {
      final conf = diseaseConfidences?[classId];
      if (conf != null && conf > 0) {
        final pct = conf <= 1.0 ? (conf * 100).round() : conf.round();
        return 'dengan keyakinan $pct persen';
      }
      return '';
    }

    // 3. Ambil daftar penyakit unik yang terdeteksi
    final uniqueDiseaseIds = diseases.toSet().toList();

    String speechText;
    if (uniqueDiseaseIds.length == 1) {
      final id = uniqueDiseaseIds.first;
      final name = ModelConstants.classDisplayNames[id] ?? id;
      final confText = getConfText(id);
      if (confText.isNotEmpty) {
        speechText = 'Terdeteksi penyakit $name, $confText.';
      } else {
        speechText = 'Terdeteksi penyakit $name.';
      }
    } else if (uniqueDiseaseIds.length == 2) {
      final id1 = uniqueDiseaseIds[0];
      final name1 = ModelConstants.classDisplayNames[id1] ?? id1;
      final conf1 = getConfText(id1);

      final id2 = uniqueDiseaseIds[1];
      final name2 = ModelConstants.classDisplayNames[id2] ?? id2;
      final conf2 = getConfText(id2);

      final part1 = conf1.isNotEmpty ? '$name1 $conf1' : name1;
      final part2 = conf2.isNotEmpty ? '$name2 $conf2' : name2;

      speechText = 'Terdeteksi dua penyakit: $part1, dan $part2.';
    } else {
      // Lebih dari 2 penyakit — sebutkan semuanya secara urut
      final parts = <String>[];
      for (final id in uniqueDiseaseIds) {
        final name = ModelConstants.classDisplayNames[id] ?? id;
        final conf = getConfText(id);
        final item = conf.isNotEmpty ? '$name $conf' : name;
        parts.add(item);
      }
      final allExceptLast = parts.sublist(0, parts.length - 1).join(', ');
      speechText =
          'Terdeteksi ${uniqueDiseaseIds.length} penyakit: $allExceptLast, dan ${parts.last}.';
    }

    if (severityLevel != null && severityLevel.isNotEmpty) {
      speechText += ' Tingkat keparahan: $severityLevel.';
    }

    await speak(speechText);
  }
}
