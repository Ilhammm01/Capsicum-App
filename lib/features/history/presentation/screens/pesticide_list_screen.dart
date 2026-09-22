import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';
import '../../../scan_detail/presentation/widgets/ingredient_detail_sheet.dart';

/// Screen menampilkan daftar rekomendasi bahan aktif/kelompok produk
/// yang dikelompokkan per kategori dari seluruh kelas penyakit.
class PesticideListScreen extends StatefulWidget {
  const PesticideListScreen({super.key});

  @override
  State<PesticideListScreen> createState() => _PesticideListScreenState();
}

class _PesticideListScreenState extends State<PesticideListScreen> {
  List<_ProductEntry> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPesticideInfo();
  }

  Future<void> _loadPesticideInfo() async {
    try {
      final ingredientRepo = IngredientRepository();
      await ingredientRepo.loadIfNeeded();

      final diseaseRepo = DiseaseInfoRepository();
      await diseaseRepo.loadIfNeeded();

      final List<_ProductEntry> loadedProducts = [];

      for (final ing in ingredientRepo.getAll()) {
        final p = ProductRecommendation(
          category: ing.type,
          activeIngredients: [ing.name],
          note: ing.note,
        );

        // Map recommended_for ids to their actual names
        // or just use targets if recommended_for is empty
        String diseaseNames = '-';
        if (ing.targets.isNotEmpty) {
          diseaseNames = ing.targets.take(2).join(', ');
          if (ing.targets.length > 2) diseaseNames += '...';
        }

        loadedProducts.add(_ProductEntry(
          recommendation: p,
          diseaseNameId: diseaseNames,
        ));
      }

      setState(() {
        _products = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading pesticide info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Informasi Bahan Aktif',
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(
                  child: Text(
                    'Tidak ada rekomendasi produk tersedia.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final entry = _products[index];
                    return _buildProductCard(entry);
                  },
                ),
    );
  }

  Widget _buildProductCard(_ProductEntry entry) {
    final p = entry.recommendation;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Karena data aslinya adalah Bahan Aktif, lebih baik menampilkannya
            // lewat IngredientDetailSheet (sama seperti di ScanDetail).
            showIngredientDetail(context, p.activeIngredients.first);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.flaskConical,
                      size: 32,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.category,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Untuk: ${entry.diseaseNameId}',
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductEntry {
  final ProductRecommendation recommendation;
  final String diseaseNameId;
  _ProductEntry({required this.recommendation, required this.diseaseNameId});
}
