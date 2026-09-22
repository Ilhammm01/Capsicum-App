import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';
import 'ingredient_detail_sheet.dart';

/// Screen menampilkan daftar rekomendasi produk/bahan aktif per kategori
/// berdasarkan kelas penyakit yang terdeteksi.
class RecommendedProductsWidget extends StatelessWidget {
  final List<ProductRecommendation> products;

  const RecommendedProductsWidget({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Text(
          'Rekomendasi Bahan Aktif',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            fontFamily: 'Google Sans',
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilihan bahan aktif berdasarkan kelas hasil deteksi.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.onSurfaceVariant,
            fontFamily: 'Google Sans',
          ),
        ),
        const SizedBox(height: 16),

        // Kartu per kategori
        ...products.map((p) => _buildCategoryCard(context, p)),

        const SizedBox(height: 16),

        // Warning Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE1B9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(LucideIcons.triangleAlert,
                    color: Color(0xFF6B4D20), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      color: Color(0xFF533F23),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                          text:
                              'Gunakan hanya produk yang terdaftar untuk tanaman cabai dan ikuti petunjuk label. '),
                      TextSpan(
                        text:
                            'Hasil deteksi bersifat bantuan identifikasi visual, bukan diagnosis laboratorium.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      BuildContext context, ProductRecommendation product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kategori
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(LucideIcons.flaskConical,
                    size: 16, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bahan Aktif
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: product.activeIngredients
                .map((ingredient) => _buildIngredientChip(context, ingredient))
                .toList(),
          ),

          // Catatan
          if (product.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              product.note,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIngredientChip(BuildContext context, String ingredient) {
    return GestureDetector(
      onTap: () => showIngredientDetail(context, ingredient),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ingredient,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryGreenDark,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.info,
              size: 12,
              color: AppTheme.primaryGreenDark,
            ),
          ],
        ),
      ),
    );
  }
}
