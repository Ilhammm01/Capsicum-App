import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/scan_history_model.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared_data/widgets/confirm_dialog.dart';

class HistoryGridItem extends StatelessWidget {
  final ScanHistoryModel model;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryGridItem({
    super.key,
    required this.model,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // === THUMBNAIL ===
            _buildThumbnail(),

            // === GRADIENT OVERLAY BAWAH ===
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEE000000), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Severity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getSeverityColor(model.severityLevel),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        model.severityLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Google Sans',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormatter.formatRelative(model.scannedAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontFamily: 'Google Sans',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // === MENU TITIK TIGA ===
            Positioned(
              top: 6,
              right: 6,
              child: _OptionsMenu(onDelete: onDelete),
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
      child: const Icon(
        LucideIcons.imageOff,
        color: AppTheme.onSurfaceVariant,
        size: 40,
      ),
    );
  }
}

class _OptionsMenu extends StatelessWidget {
  final VoidCallback onDelete;

  const _OptionsMenu({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => buildStyledPopupItems([
        const StyledPopupItem(
          value: 'delete',
          icon: LucideIcons.trash2,
          label: 'Hapus',
          color: AppTheme.severityBerat,
        ),
      ]),
      icon: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(LucideIcons.ellipsisVertical,
            color: Colors.white, size: 16),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      color: AppTheme.surface,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 180),
    );
  }
}
