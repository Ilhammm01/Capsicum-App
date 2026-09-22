import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DiseaseListTile extends StatefulWidget {
  final DiseaseInfo disease;
  final double? confidence;
  final int? detectionCount;

  const DiseaseListTile({
    super.key,
    required this.disease,
    this.confidence,
    this.detectionCount,
  });

  @override
  State<DiseaseListTile> createState() => _DiseaseListTileState();
}

class _DiseaseListTileState extends State<DiseaseListTile> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                color: widget.disease.isHealthy
                    ? AppTheme.severityRingan
                    : AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disease name + confidence badge + expand icon
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.disease.nama,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Google Sans',
                            color: AppTheme.onSurface,
                          ),
                        ),
                      ),
                      if (widget.confidence != null) ...[
                        const SizedBox(width: 8),
                        _ConfidenceBadge(confidence: widget.confidence!),
                      ],
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 18,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Detection count
                  if (widget.detectionCount != null &&
                      widget.detectionCount! > 0) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.crop_square_rounded,
                          size: 13,
                          color:
                              AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.detectionCount} area terdeteksi',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                            fontFamily: 'Google Sans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],

                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      widget.disease.deskripsi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceVariant,
                        fontFamily: 'Google Sans',
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.disease.deskripsi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                            fontFamily: 'Google Sans',
                            height: 1.5,
                          ),
                        ),
                        if (widget.disease.symptoms.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Gejala Umum:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                              fontFamily: 'Google Sans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...widget.disease.symptoms.map((symptom) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.onSurfaceVariant)),
                                    Expanded(
                                      child: Text(
                                        symptom,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.onSurfaceVariant,
                                          fontFamily: 'Google Sans',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  const _ConfidenceBadge({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).toStringAsFixed(0);
    final color = confidence >= 0.7
        ? AppTheme.primaryGreen
        : confidence >= 0.4
            ? AppTheme.severitySedang
            : AppTheme.severityBerat;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: 'Google Sans',
          color: color,
        ),
      ),
    );
  }
}
