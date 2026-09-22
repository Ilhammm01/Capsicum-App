// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanHistoryModelAdapter extends TypeAdapter<ScanHistoryModel> {
  @override
  final int typeId = 0;

  @override
  ScanHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanHistoryModel(
      imagePath: fields[0] as String,
      scannedAt: fields[1] as DateTime,
      detectedDiseaseIds: (fields[2] as List).cast<String>(),
      severityLevel: fields[3] as String,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
      locationName: fields[6] as String?,
      averageConfidence: fields[7] as double,
      aiRecommendation: fields[8] as String?,
      diseaseConfidences: (fields[9] as Map?)?.cast<String, double>(),
      diseaseDetectionCounts: (fields[10] as Map?)?.cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, ScanHistoryModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.scannedAt)
      ..writeByte(2)
      ..write(obj.detectedDiseaseIds)
      ..writeByte(3)
      ..write(obj.severityLevel)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.locationName)
      ..writeByte(7)
      ..write(obj.averageConfidence)
      ..writeByte(8)
      ..write(obj.aiRecommendation)
      ..writeByte(9)
      ..write(obj.diseaseConfidences)
      ..writeByte(10)
      ..write(obj.diseaseDetectionCounts);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
