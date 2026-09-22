import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import 'disease_detail_screen.dart';

class DiseaseInfoScreen extends StatefulWidget {
  const DiseaseInfoScreen({super.key});

  @override
  State<DiseaseInfoScreen> createState() => _DiseaseInfoScreenState();
}

class _DiseaseInfoScreenState extends State<DiseaseInfoScreen> {
  List<dynamic> _diseases = [];
  Map<String, String> _firstImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiseaseInfo();
  }

  Future<void> _loadDiseaseInfo() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/disease_info.json');
      final Map<String, dynamic> data = json.decode(jsonString);

      final manifestContent =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = manifestContent.listAssets();

      final List<dynamic> classes = data['classes'] ?? [];
      final Map<String, String> firstImages = {};

      for (var disease in classes) {
        final String diseaseId = disease['id'] ?? '';
        final imagePaths = allAssets
            .where((String key) =>
                key.startsWith('assets/images/$diseaseId/') &&
                key.endsWith('.webp'))
            .toList();

        if (imagePaths.isNotEmpty) {
          firstImages[diseaseId] = imagePaths.first;
        } else {
          firstImages[diseaseId] = 'assets/images/$diseaseId.webp';
        }
      }

      setState(() {
        _diseases = classes;
        _firstImages = firstImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading disease info: $e');
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
          'Informasi Penyakit Daun Cabai Besar',
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
          : _diseases.isEmpty
              ? const Center(
                  child: Text(
                    'Gagal memuat data informasi penyakit.',
                    style: TextStyle(color: AppTheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _diseases.length,
                  itemBuilder: (context, index) {
                    final disease = _diseases[index];
                    return _buildDiseaseCard(disease);
                  },
                ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> disease) {
    final nama = disease['name_id'] ?? disease['nama'] ?? 'Tidak diketahui';
    final labelModel = disease['label_model'] ?? 'Unknown Type';

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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DiseaseDetailScreen(disease: disease),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _firstImages[disease['id']] ??
                        'assets/images/${disease['id']}.webp',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        color: AppTheme.surfaceVariant,
                        child: const Icon(
                          LucideIcons.image,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labelModel,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          color: AppTheme.onSurfaceVariant,
                        ),
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
