import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';

class RecommendationListTile extends StatelessWidget {
  final DiseaseInfo disease;

  const RecommendationListTile({super.key, required this.disease});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.leaf,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  disease.nama,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Google Sans',
                    color: AppTheme.primaryGreenDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...disease.rekomendasi.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 10, top: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                        fontFamily: 'Google Sans',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
