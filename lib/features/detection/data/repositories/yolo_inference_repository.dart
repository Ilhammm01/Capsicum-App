import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/detection_result_model.dart';
import '../../../../core/constants/app_constants.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';

// ═══════════════════════════════════════════════════════════════
//  Isolate-safe types & top-level preprocessing
// ═══════════════════════════════════════════════════════════════

class _FrameData {
  final Uint8List yBytes;
  final Uint8List uBytes;
  final Uint8List vBytes;
  final int width;
  final int height;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
  final double inputScale;
  final int inputZeroPoint;
  final int inputTypeIndex; // 0: float32, 1: int8, 2: uint8

  _FrameData({
    required this.yBytes,
    required this.uBytes,
    required this.vBytes,
    required this.width,
    required this.height,
    required this.sensorOrientation,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
    this.inputScale = 1.0,
    this.inputZeroPoint = 0,
    this.inputTypeIndex = 0,
  });

  final int sensorOrientation;
}

class _PreprocessResult {
  final dynamic tensor; // Will be Float32List, Int8List, or Uint8List
  final double padLeft;
  final double padTop;
  final double scale;

  const _PreprocessResult({
    required this.tensor,
    required this.padLeft,
    required this.padTop,
    required this.scale,
  });
}

/// Single-pass YUV420 → letterbox → NCHW float32 tensor
_PreprocessResult _preprocessFrame(_FrameData d) {
  const int outSize = 640;

  final bool isRotated =
      d.sensorOrientation == 90 || d.sensorOrientation == 270;
  final int logicalWidth = isRotated ? d.height : d.width;
  final int logicalHeight = isRotated ? d.width : d.height;

  final double scaleX = outSize / logicalWidth;
  final double scaleY = outSize / logicalHeight;
  final double scale = scaleX < scaleY ? scaleX : scaleY;
  final double newW = logicalWidth * scale;
  final double newH = logicalHeight * scale;
  final double padLeft = (outSize - newW) / 2;
  final double padTop = (outSize - newH) / 2;

  final int planeSize = outSize * outSize;

  // Choose tensor backend
  final dynamic tensor;
  if (d.inputTypeIndex == 1) {
    tensor = Int8List(3 * outSize * outSize);
  } else if (d.inputTypeIndex == 2) {
    tensor = Uint8List(3 * outSize * outSize);
  } else {
    tensor = Float32List(3 * outSize * outSize);
  }

  final int yRowStride = d.yRowStride;
  final int uvRowStride = d.uvRowStride;
  final int uvPixelStride = d.uvPixelStride;

  for (int oy = 0; oy < outSize; oy++) {
    for (int ox = 0; ox < outSize; ox++) {
      final int linearIdx = oy * outSize + ox;
      final double lx = (ox - padLeft) / scale;
      final double ly = (oy - padTop) / scale;

      if (ox < padLeft ||
          ox >= padLeft + newW ||
          oy < padTop ||
          oy >= padTop + newH) {
        if (d.inputTypeIndex == 1) {
          tensor[linearIdx] = d.inputZeroPoint.clamp(-128, 127);
          tensor[planeSize + linearIdx] = tensor[linearIdx];
          tensor[planeSize * 2 + linearIdx] = tensor[linearIdx];
        } else if (d.inputTypeIndex == 2) {
          tensor[linearIdx] = d.inputZeroPoint.clamp(0, 255);
          tensor[planeSize + linearIdx] = tensor[linearIdx];
          tensor[planeSize * 2 + linearIdx] = tensor[linearIdx];
        } else {
          tensor[linearIdx] = 0.0;
          tensor[planeSize + linearIdx] = 0.0;
          tensor[planeSize * 2 + linearIdx] = 0.0;
        }
        continue;
      }

      final int sx = lx.toInt().clamp(0, logicalWidth - 1);
      final int sy = ly.toInt().clamp(0, logicalHeight - 1);

      int rawX = sx;
      int rawY = sy;

      if (d.sensorOrientation == 90) {
        rawX = sy;
        rawY = d.height - 1 - sx;
      } else if (d.sensorOrientation == 270) {
        rawX = d.width - 1 - sy;
        rawY = sx;
      } else if (d.sensorOrientation == 180) {
        rawX = d.width - 1 - sx;
        rawY = d.height - 1 - sy;
      }

      rawX = rawX.clamp(0, d.width - 1);
      rawY = rawY.clamp(0, d.height - 1);

      final int yVal = d.yBytes[rawY * yRowStride + rawX];
      final int uvIdx = (rawY ~/ 2) * uvRowStride + (rawX ~/ 2) * uvPixelStride;
      final int u = d.uBytes[uvIdx] - 128;
      final int v = d.vBytes[uvIdx] - 128;

      final double r = (yVal + 1.402 * v).clamp(0.0, 255.0) / 255.0;
      final double g =
          (yVal - 0.344136 * u - 0.714136 * v).clamp(0.0, 255.0) / 255.0;
      final double b = (yVal + 1.772 * u).clamp(0.0, 255.0) / 255.0;

      if (d.inputTypeIndex == 1) {
        tensor[linearIdx] =
            ((r / d.inputScale) + d.inputZeroPoint).toInt().clamp(-128, 127);
        tensor[planeSize + linearIdx] =
            ((g / d.inputScale) + d.inputZeroPoint).toInt().clamp(-128, 127);
        tensor[planeSize * 2 + linearIdx] =
            ((b / d.inputScale) + d.inputZeroPoint).toInt().clamp(-128, 127);
      } else if (d.inputTypeIndex == 2) {
        tensor[linearIdx] =
            ((r / d.inputScale) + d.inputZeroPoint).toInt().clamp(0, 255);
        tensor[planeSize + linearIdx] =
            ((g / d.inputScale) + d.inputZeroPoint).toInt().clamp(0, 255);
        tensor[planeSize * 2 + linearIdx] =
            ((b / d.inputScale) + d.inputZeroPoint).toInt().clamp(0, 255);
      } else {
        tensor[linearIdx] = r.toDouble();
        tensor[planeSize + linearIdx] = g.toDouble();
        tensor[planeSize * 2 + linearIdx] = b.toDouble();
      }
    }
  }

  return _PreprocessResult(
    tensor: tensor,
    padLeft: padLeft,
    padTop: padTop,
    scale: scale,
  );
}

// ═══════════════════════════════════════════════════════════════
//  Repository
// ═══════════════════════════════════════════════════════════════

class YoloInferenceRepository {
  static final YoloInferenceRepository _instance =
      YoloInferenceRepository._internal();
  factory YoloInferenceRepository() => _instance;
  YoloInferenceRepository._internal();

  Interpreter? _interpreter;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<bool> loadModel() async {
    if (_isLoaded) return true;

    final String asset = AssetPaths.modelPath;
    final String variant = InferenceConfig.activeModel.name.toUpperCase();

    debugPrint('[YOLO] Loading variant=$variant asset=$asset');

    Future<bool> tryLoad(String label, InterpreterOptions opts) async {
      try {
        final interp = await Interpreter.fromAsset(asset, options: opts);
        // Alokasi tensor eksplisit sebelum menetapkan _isLoaded.
        // Jika graph tidak valid (misal operator TRANSPOSE salah), akan throw di sini.
        interp.allocateTensors();
        _interpreter = interp;
        _isLoaded = true;
        _logModelInfo(label, variant, asset);
        return true;
      } catch (e) {
        debugPrint('[YOLO] $label failed: $e');
        return false;
      }
    }

    if (Platform.isAndroid) {
      if (await tryLoad(
          'GPU Delegate',
          InterpreterOptions()
            ..threads = 4
            ..addDelegate(GpuDelegateV2()))) {
        return true;
      }
      if (await tryLoad(
          'XNNPack Delegate',
          InterpreterOptions()
            ..threads = 4
            ..addDelegate(XNNPackDelegate()))) {
        return true;
      }
    } else if (Platform.isIOS) {
      if (await tryLoad(
          'iOS GPU Delegate',
          InterpreterOptions()
            ..threads = 4
            ..addDelegate(GpuDelegate()))) {
        return true;
      }
    }

    // Fallback: CPU standar
    if (await tryLoad('CPU Fallback', InterpreterOptions()..threads = 4)) {
      return true;
    }

    debugPrint('[YOLO] ❌ All delegates failed. Model not loaded.');
    return false;
  }

  void _logModelInfo(String delegate, String variant, String asset) {
    if (_interpreter == null) return;
    final inT = _interpreter!.getInputTensor(0);
    final outT = _interpreter!.getOutputTensor(0);
    debugPrint('=========================================');
    debugPrint('[YOLO] ✅ Model loaded ($delegate)');
    debugPrint('[YOLO] Variant : $variant');
    debugPrint('[YOLO] Asset   : $asset');
    debugPrint('[YOLO] Input   : shape=${inT.shape}  type=${inT.type}'
        '  scale=${inT.params.scale}  zp=${inT.params.zeroPoint}');
    debugPrint('[YOLO] Output  : shape=${outT.shape}  type=${outT.type}'
        '  scale=${outT.params.scale}  zp=${outT.params.zeroPoint}');
    debugPrint('=========================================');
  }

  Future<(List<DetectionResult>, Map<String, int>)> runInference({
    required CameraImage cameraImage,
    required int imageWidth,
    required int imageHeight,
    required int sensorOrientation,
  }) async {
    if (!_isLoaded || _interpreter == null) {
      return (<DetectionResult>[], <String, int>{});
    }
    try {
      final inTensor = _interpreter!.getInputTensor(0);
      final inType = inTensor.type.toString();
      int typeIdx = 0;
      if (inType.contains('int8')) {
        typeIdx = 1;
      } else if (inType.contains('uint8')) {
        typeIdx = 2;
      }

      final outTensor = _interpreter!.getOutputTensor(0);
      final outType = outTensor.type.toString();
      bool outIsInt8 = outType.contains('int8');
      bool outIsUint8 = outType.contains('uint8');

      // CRITICAL FIX: Synchronously copy the native memory to Dart heap using fromList
      // before crossing the asynchronous isolate boundary, to prevent the
      // camera plugin from freeing the native buffer and causing "Input tensor lacks data" crash.
      final frameData = _FrameData(
        yBytes: Uint8List.fromList(cameraImage.planes[0].bytes),
        uBytes: Uint8List.fromList(cameraImage.planes[1].bytes),
        vBytes: Uint8List.fromList(cameraImage.planes[2].bytes),
        width: cameraImage.width,
        height: cameraImage.height,
        sensorOrientation: sensorOrientation,
        yRowStride: cameraImage.planes[0].bytesPerRow,
        uvRowStride: cameraImage.planes[1].bytesPerRow,
        uvPixelStride: cameraImage.planes[1].bytesPerPixel ?? 1,
        inputTypeIndex: typeIdx,
        inputScale: inTensor.params.scale == 0.0 ? 1.0 : inTensor.params.scale,
        inputZeroPoint: inTensor.params.zeroPoint,
      );

      final swPrep = Stopwatch()..start();
      final prep = await compute(_preprocessFrame, frameData);
      swPrep.stop();

      final swInf = Stopwatch()..start();
      // Kirim tensor menggunakan raw byte copy langsung ke slot input model.
      // Ini mempertahankan shape [1,3,640,640] yang sudah di-allocateTensors()
      // saat loadModel(), sehingga tidak terjadi reshape ke rank-1 [1228800].
      // Untuk model NCHW [1, 3, 640, 640], passing Float32List flat langsung ke interpreter.run()
      // menyebabkan tflite_flutter memanggil resizeInputTensor([1228800]) yang mengubah rank-4 menjadi rank-1,
      // sehingga operator TRANSPOSE gagal (dims 4 != 1).
      // Solusi: Gunakan runForMultipleInputs dengan input berstruktur 4D [1, 3, 640, 640]
      // atau set Tensor.data langsung menggunakan Float32List.buffer tanpa meresize tensor shape.
      // Initialize flat float array representing the inputs
      final Float32List inputFlat = prep.tensor is Float32List
          ? (prep.tensor as Float32List)
          : Float32List.fromList(prep.tensor);

      // Initialize flat array mapping to outputs
      final flatOutputBuffer = Float32List(1 * 9 * 8400);

      // Expose underlying bytes for direct memory transfer (memcpy)
      final inputBytes = inputFlat.buffer.asUint8List();
      final outputBytes = flatOutputBuffer.buffer.asUint8List();

      // Bypassing multidimensional Lists, giving memory directly!
      _interpreter!.runForMultipleInputs([inputBytes], {0: outputBytes});

      swInf.stop();

      final (results, decodeMs, transformMs, nmsMs) = _decodeFlatBuffer(
        flatOutputBuffer,
        isQuantized: outIsInt8 || outIsUint8,
        outScale: outTensor.params.scale == 0.0 ? 1.0 : outTensor.params.scale,
        outZeroPoint: outTensor.params.zeroPoint,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        padLeft: prep.padLeft,
        padTop: prep.padTop,
        scale: prep.scale,
      );

      final timings = {
        'preprocess': swPrep.elapsedMilliseconds,
        'inference': swInf.elapsedMilliseconds,
        'decode': decodeMs,
        'transform': transformMs,
        'nms': nmsMs,
      };

      return (results, timings);
    } catch (e, st) {
      debugPrint('================= TFLITE INT8 CRASH =================');
      debugPrint('[YOLO] runInference error: $e');
      debugPrint('[YOLO] StackTrace: $st');
      if (_interpreter != null) {
        final inT = _interpreter!.getInputTensor(0);
        final outT = _interpreter!.getOutputTensor(0);
        debugPrint(
            '[YOLO] Model Expected Input : Type: ${inT.type}, Shape: ${inT.shape}, Bytes: ${inT.numBytes()}');
        debugPrint(
            '[YOLO] Model Expected Output: Type: ${outT.type}, Shape: ${outT.shape}, Bytes: ${outT.numBytes()}');
      }
      debugPrint('=====================================================');
      return (<DetectionResult>[], <String, int>{});
    }
  }

  // Tuple: (Results, decodeMs, transformMs, nmsMs)
  (List<DetectionResult>, int, int, int) _decodeFlatBuffer(
    dynamic outputBuffer, {
    required bool isQuantized,
    required double outScale,
    required int outZeroPoint,
    required int imageWidth,
    required int imageHeight,
    required double padLeft,
    required double padTop,
    required double scale,
  }) {
    final swDecode = Stopwatch()..start();
    final numClasses = ModelConstants.numClasses;
    final int numAnchors = outputBuffer.length ~/ (4 + numClasses);
    final output = List.generate(
      4 + numClasses,
      (c) => outputBuffer.sublist(c * numAnchors, (c + 1) * numAnchors),
    );
    final normBoxes = <List<double>>[];
    final scores = <double>[];
    final classIdxList = <int>[];

    // Tahap 1: Ekstrak box & class score
    double globalMaxScore = 0.0;
    for (int j = 0; j < numAnchors; j++) {
      double maxScore = 0.0;
      int bestClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final rawVal = output[4 + c][j];
        final double s = isQuantized
            ? (rawVal - outZeroPoint) * outScale
            : rawVal.toDouble();
        if (s > maxScore) {
          maxScore = s;
          bestClass = c;
        }
      }
      if (maxScore > globalMaxScore) globalMaxScore = maxScore;
      if (maxScore < InferenceConfig.confidenceThreshold) continue;

      final rawCx = output[0][j];
      final rawCy = output[1][j];
      final rawCw = output[2][j];
      final rawCh = output[3][j];

      final cx =
          (isQuantized ? (rawCx - outZeroPoint) * outScale : rawCx.toDouble()) *
              640.0;
      final cy =
          (isQuantized ? (rawCy - outZeroPoint) * outScale : rawCy.toDouble()) *
              640.0;
      final bw =
          (isQuantized ? (rawCw - outZeroPoint) * outScale : rawCw.toDouble()) *
              640.0;
      final bh =
          (isQuantized ? (rawCh - outZeroPoint) * outScale : rawCh.toDouble()) *
              640.0;

      normBoxes.add([cx, cy, bw, bh]);
      scores.add(maxScore);
      classIdxList.add(bestClass);
    }
    swDecode.stop();
    debugPrint(
        '[YOLO-TRACE] Global Max Confidence this frame: ${(globalMaxScore * 100).toStringAsFixed(2)}%');

    // Tahap 2: Bounding Box Transformation
    final swTransform = Stopwatch()..start();
    final scaledBoxes = <Rect>[];
    for (final b in normBoxes) {
      final cx = b[0], cy = b[1], bw = b[2], bh = b[3];
      final rx1 =
          ((cx - bw / 2 - padLeft) / scale).clamp(0.0, imageWidth.toDouble());
      final ry1 =
          ((cy - bh / 2 - padTop) / scale).clamp(0.0, imageHeight.toDouble());
      final rx2 =
          ((cx + bw / 2 - padLeft) / scale).clamp(0.0, imageWidth.toDouble());
      final ry2 =
          ((cy + bh / 2 - padTop) / scale).clamp(0.0, imageHeight.toDouble());

      if (rx2 > rx1 && ry2 > ry1) {
        scaledBoxes.add(Rect.fromLTRB(rx1, ry1, rx2, ry2));
      } else {
        scaledBoxes.add(Rect.zero);
      }
    }
    swTransform.stop();

    // Tahap 3: NMS
    final swNms = Stopwatch()..start();
    final results = _applyNms(scaledBoxes, scores, classIdxList);
    swNms.stop();

    return (
      results,
      swDecode.elapsedMilliseconds,
      swTransform.elapsedMilliseconds,
      swNms.elapsedMilliseconds
    );
  }

  List<DetectionResult> _applyNms(
    List<Rect> boxes,
    List<double> scores,
    List<int> classIdxList,
  ) {
    if (boxes.isEmpty) return [];

    final indices = List.generate(boxes.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));

    final suppressed = <int>{};
    final kept = <int>[];

    for (final i in indices) {
      if (suppressed.contains(i)) continue;
      kept.add(i);
      for (final j in indices) {
        if (i == j || suppressed.contains(j)) continue;
        if (classIdxList[i] != classIdxList[j]) continue;
        if (_iou(boxes[i], boxes[j]) > InferenceConfig.iouThreshold) {
          suppressed.add(j);
        }
      }
    }

    return kept.map((i) {
      final cid = ModelConstants.classIds[classIdxList[i]];
      return DetectionResult(
        classId: cid,
        className: ModelConstants.classDisplayNames[cid] ?? cid,
        confidence: scores[i],
        boundingBox: boxes[i],
      );
    }).toList();
  }

  double _iou(Rect a, Rect b) {
    final inter = a.intersect(b);
    if (inter.isEmpty) return 0.0;
    final interArea = inter.width * inter.height;
    final unionArea = a.width * a.height + b.width * b.height - interArea;
    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

double calculateSeverityRatio(
  List<DetectionResult> results,
  int frameWidth,
  int frameHeight,
) {
  if (results.isEmpty) return 0.0;
  final frameArea = frameWidth * frameHeight;
  if (frameArea == 0) return 0.0;
  final totalArea = results.fold<double>(
      0.0, (sum, r) => sum + r.boundingBox.width * r.boundingBox.height);
  return (totalArea / frameArea).clamp(0.0, 1.0);
}
