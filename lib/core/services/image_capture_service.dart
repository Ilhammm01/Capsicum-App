import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImageCaptureService {
  /// Ambil screenshot dari RepaintBoundary menggunakan GlobalKey
  /// dan simpan ke local storage. Returns path file yang disimpan.
  static Future<String?> captureAndSave(
    GlobalKey repaintKey, {
    double pixelRatio = 2.0,
    String directoryName = 'capsicum_captures',
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return await _saveToFile(bytes, directoryName);
    } catch (e) {
      return null;
    }
  }

  static Future<String> _saveToFile(
      Uint8List bytes, String directoryName) async {
    final dir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${dir.path}/$directoryName');
    if (!scanDir.existsSync()) {
      scanDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${scanDir.path}/scan_$timestamp.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
