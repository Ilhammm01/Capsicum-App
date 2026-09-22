import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class DiseaseSummaryCard extends StatelessWidget {
  final int diseaseCount;
  final String severityLevel;
  final double confidence;
  final int? totalDetections;

  const DiseaseSummaryCard({
    super.key,
    required this.diseaseCount,
    required this.severityLevel,
    required this.confidence,
    this.totalDetections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          _SummaryCell(
            value: '$diseaseCount',
            label: 'Jenis\nPenyakit',
            color: AppTheme.onSurface,
            isFirst: true,
          ),
          _VerticalDivider(),
          _SummarySeverityCell(severityLevel: severityLevel),
          _VerticalDivider(),
          _SummaryCell(
            value: totalDetections != null
                ? '$totalDetections'
                : '${(confidence * 100).toStringAsFixed(0)}%',
            label: totalDetections != null ? 'Total\nDeteksi' : 'Confidence',
            color: AppTheme.primaryGreen,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isFirst;
  final bool isLast;

  const _SummaryCell({
    required this.value,
    required this.label,
    required this.color,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Google Sans',
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
                fontFamily: 'Google Sans',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummarySeverityCell extends StatelessWidget {
  final String severityLevel;
  const _SummarySeverityCell({required this.severityLevel});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getSeverityColor(severityLevel);
    final bgColor = AppTheme.getSeverityBgColor(severityLevel);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                severityLevel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Google Sans',
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Estimasi\nKeparahan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.onSurfaceVariant,
                fontFamily: 'Google Sans',
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: AppTheme.divider);
  }
}
