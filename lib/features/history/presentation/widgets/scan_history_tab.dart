import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/scan_history_model.dart';
import '../../data/repositories/history_repository.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared_data/widgets/confirm_dialog.dart';

class ScanHistoryTab extends StatelessWidget {
  const ScanHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ScanHistoryModel>>(
      valueListenable: HistoryRepository.box.listenable(),
      builder: (context, box, _) {
        final items = HistoryRepository.getAllScans();
        if (items.isEmpty) return _buildEmpty();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScanListTile(
                model: item,
                onTap: () => _openDetail(context, item),
                onDelete: () => _deleteScan(context, item),
              ),
            );
          },
        );
      },
    );
  }

  void _openDetail(BuildContext context, ScanHistoryModel model) {
    context.pushNamed('scanDetail', extra: ScanDetailArgs.fromHistory(model));
  }

  Future<void> _deleteScan(BuildContext context, ScanHistoryModel model) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: LucideIcons.trash2,
      iconColor: AppTheme.severityBerat,
      iconBackground: AppTheme.severityBerat.withValues(alpha: 0.1),
      title: 'Hapus Scan?',
      message:
          'Riwayat scan ini akan dihapus permanen dan tidak dapat dikembalikan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
    );
    if (confirmed == true) {
      if (model.imagePath.isNotEmpty) {
        final file = File(model.imagePath);
        if (file.existsSync()) file.deleteSync();
      }
      await HistoryRepository.deleteScan(model);
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.scanLine,
              size: 32,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat scan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontFamily: 'Google Sans',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tekan tombol Scan di kamera\nuntuk melihat hasil deteksi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'Google Sans',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Scan List Tile — matches new list view mockup
// ============================================================
class _ScanListTile extends StatelessWidget {
  final ScanHistoryModel model;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ScanListTile({
    required this.model,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Generate text for disease names
    final diseaseNames = model.detectedDiseaseIds;
    final diseaseText = diseaseNames.isNotEmpty
        ? diseaseNames
            .map((id) => ModelConstants.classDisplayNames[id] ?? id)
            .join(', ')
        : 'Tidak ada indikasi';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete, // allow long press to delete
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16), // matching mockup
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // === THUMBNAIL LEFT ===
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: _buildThumbnail(),
              ),
            ),
            const SizedBox(width: 14),

            // === INFO RIGHT ===
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diseaseText,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatFull(model.scannedAt), // "24 Juli 2026"
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // === CHEVRON RIGHT ===
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppTheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final file = File(model.imagePath);
    if (model.imagePath.isNotEmpty && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppTheme.surfaceVariant,
      child: const Center(
        child: Icon(
          LucideIcons.imageOff,
          color: AppTheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}
