import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import 'disease_info_screen.dart';
import 'pesticide_list_screen.dart';

class InformationHubScreen extends StatelessWidget {
  const InformationHubScreen({super.key});

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
          'Pusat Informasi',
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildOptionCard(
              context: context,
              title: 'Informasi Penyakit',
              subtitle: 'Pelajari berbagai jenis penyakit dan gejalanya.',
              icon: LucideIcons.bug,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DiseaseInfoScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context: context,
              title: 'Informasi Produk Pestisida',
              subtitle:
                  'Daftar lengkap produk pestisida, komposisi, serta detailnya.',
              icon: LucideIcons.testTube2,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PesticideListScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight,
                color: AppTheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
