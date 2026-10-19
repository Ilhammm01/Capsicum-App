import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class ImageCaptureService {
  /// Ambil screenshot dari RepaintBoundary menggunakan GlobalKey
  /// dan simpan ke local storage menggunakan Isolate agar tidak memblokir UI.
  static Future<String?> captureAndSave(
    GlobalKey repaintKey, {
    double pixelRatio = 1.5, // Dikurangi dari 2.0 untuk mempercepat capture
    String directoryName = 'capsicum_captures',
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Ambil pixel secara mentah (uncompressed) di UI Thread, ini sangat cepat
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      final dir = await getApplicationDocumentsDirectory();

      // Kirim data ke background Isolate untuk proses kompresi ke PNG yang berat
      return await compute(_encodeAndSavePng, {
        'bytes': bytes,
        'width': width,
        'height': height,
        'dirPath': dir.path,
        'dirName': directoryName,
      });
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  // Fungsi statis top-level untuk Isolate
  static Future<String> _encodeAndSavePng(Map<String, dynamic> params) async {
    final bytes = params['bytes'] as Uint8List;
    final width = params['width'] as int;
    final height = params['height'] as int;
    final dirPath = params['dirPath'] as String;
    final dirName = params['dirName'] as String;

    final scanDir = Directory('$dirPath/$dirName');
    if (!scanDir.existsSync()) {
      scanDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${scanDir.path}/scan_$timestamp.jpg');
    // Menyimpan sebagai JPG biasanya lebih cepat dan ukurannya kecil, tapi jika butuh PNG:

    // 1. Buat obejk image
    final image = img.Image.fromBytes(
      width: width,
      height: height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.rgba,
    );

    // 2. Encode
    // Encode JPG jauh lebih cepat daripada Encode PNG
    final encoded = img.encodeJpg(image, quality: 85);

    // 3. Simpan
    await file.writeAsBytes(encoded);
    return file.path;
  }
}
