import 'package:flutter_test/flutter_test.dart';
import 'package:capsicum/core/constants/app_constants.dart';

void main() {
  group('SeverityThresholds', () {
    test('classify returns Ringan for ratio below lightMax', () {
      expect(SeverityThresholds.classify(0.0), 'Ringan');
      expect(SeverityThresholds.classify(0.10), 'Ringan');
      expect(SeverityThresholds.classify(0.149), 'Ringan');
    });

    test('classify returns Sedang for ratio between lightMax and moderateMax',
        () {
      expect(SeverityThresholds.classify(0.15), 'Sedang');
      expect(SeverityThresholds.classify(0.25), 'Sedang');
      expect(SeverityThresholds.classify(0.399), 'Sedang');
    });

    test('classify returns Berat for ratio above moderateMax', () {
      expect(SeverityThresholds.classify(0.40), 'Berat');
      expect(SeverityThresholds.classify(0.75), 'Berat');
      expect(SeverityThresholds.classify(1.0), 'Berat');
    });
  });

  group('AssetPaths', () {
    test('modelPath points to tflite file', () {
      expect(AssetPaths.modelPath, endsWith('.tflite'));
    });

    test('labelsPath points to txt file', () {
      expect(AssetPaths.labelsPath, endsWith('.txt'));
    });

    test('diseaseInfoPath points to json file', () {
      expect(AssetPaths.diseaseInfoPath, endsWith('.json'));
    });
  });

  group('InferenceConfig', () {
    test('inputSize is positive', () {
      expect(InferenceConfig.inputSize, greaterThan(0));
    });

    test('throttleMs is positive', () {
      expect(InferenceConfig.throttleMs, greaterThan(0));
    });

    test('iouThreshold is between 0 and 1', () {
      expect(InferenceConfig.iouThreshold, inInclusiveRange(0.0, 1.0));
    });

    test('confidenceThreshold is between 0 and 1', () {
      expect(InferenceConfig.confidenceThreshold, inInclusiveRange(0.0, 1.0));
    });

    test('hiveBoxHistory is not empty', () {
      expect(InferenceConfig.hiveBoxHistory, isNotEmpty);
    });
  });
}
