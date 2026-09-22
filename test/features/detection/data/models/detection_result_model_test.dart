import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:capsicum/features/detection/data/models/detection_result_model.dart';

void main() {
  group('DetectionResult', () {
    late DetectionResult result;

    setUp(() {
      result = const DetectionResult(
        classId: 'antraknosa',
        className: 'Antraknosa',
        confidence: 0.95,
        boundingBox: Rect.fromLTWH(100, 100, 200, 150),
      );
    });

    test('stores classId correctly', () {
      expect(result.classId, 'antraknosa');
    });

    test('stores className correctly', () {
      expect(result.className, 'Antraknosa');
    });

    test('stores confidence correctly', () {
      expect(result.confidence, 0.95);
    });

    test('normalizedArea returns width * height', () {
      // 200 * 150 = 30000
      expect(result.normalizedArea, 30000.0);
    });

    test('toString contains class name and confidence', () {
      final str = result.toString();
      expect(str, contains('Antraknosa'));
      expect(str, contains('95.0'));
    });

  });
}
