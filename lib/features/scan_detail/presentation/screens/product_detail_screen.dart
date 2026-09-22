import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';

/// Detail view untuk satu kategori rekomendasi bahan aktif/produk.
/// Menampilkan kategori, bahan aktif, dan catatan penggunaan.
class ProductDetailScreen extends StatelessWidget {
  final ProductRecommendation product;
  final String diseaseNameId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.diseaseNameId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background behind image
      body: Stack(
        children: [
          // Background Placeholder Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              color: AppTheme.surfaceVariant,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    LucideIcons.flaskConical,
                    size: 96,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                  ),
                  Positioned(
                    bottom: 48,
                    child: Text(
                      'Ilustrasi Produk',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.55,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, spreadRadius: 0),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 16,
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                  ),
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.divider,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title and Subtitle
                    Text(
                      product.category, // e.g. "Fungisida"
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rekomendasi untuk: $diseaseNameId',
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bahan Aktif
                    const Text(
                      'Bahan Aktif:',
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.activeIngredients
                          .map((ing) => _buildIngredientChip(ing))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // Catatan Penggunaan
                    if (product.note.isNotEmpty) ...[
                      const Text(
                        'Catatan Penggunaan:',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              LucideIcons.info,
                              color: AppTheme.primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.note,
                                style: const TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 14,
                                  color: AppTheme.onSurface,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Disclaimer
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE1B9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.triangleAlert,
                              color: Color(0xFF6B4D20), size: 16),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gunakan produk yang terdaftar untuk tanaman cabai. '
                              'Hasil deteksi bersifat identifikasi visual, bukan diagnosa laboratorium.',
                              style: TextStyle(
                                fontFamily: 'Google Sans',
                                fontSize: 12,
                                color: Color(0xFF533F23),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Floating Close/Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.x,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Google Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreenDark,
        ),
      ),
    );
  }
}
