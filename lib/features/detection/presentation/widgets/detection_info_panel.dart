import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/location_service.dart';

class DetectionInfoPanel extends StatelessWidget {
  final DateTime currentTime;
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const DetectionInfoPanel({
    super.key,
    required this.currentTime,
    this.latitude,
    this.longitude,
    this.locationName,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss', 'id_ID').format(currentTime);
    final locStr = locationName ?? '-';
    final latlongStr = (latitude != null && longitude != null)
        ? LocationService.formatLatLong(latitude!, longitude!)
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Waktu', value: timeStr),
          _InfoRow(label: 'Lokasi', value: locStr),
          _InfoRow(label: 'Koordinat', value: latlongStr),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  static const _shadow = [
    Shadow(
      offset: Offset(0, 1),
      blurRadius: 4,
      color: Colors.black87,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'Google Sans',
                shadows: _shadow,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Google Sans',
                shadows: _shadow,
              ),
            ),
          ],
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
