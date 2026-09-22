import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Dialog konfirmasi yang lebih menarik dan konsisten
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconBackground,
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
  String cancelLabel = 'Batal',
  Color? confirmColor,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'confirm_dialog',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInBack,
      );
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(
          opacity: anim1,
          child: _ConfirmDialogContent(
            icon: icon,
            iconColor: iconColor,
            iconBackground: iconBackground,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            confirmColor: confirmColor ?? AppTheme.severityBerat,
          ),
        ),
      );
    },
  );
}

class _ConfirmDialogContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;

  const _ConfirmDialogContent({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // === TITLE ===
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // === MESSAGE ===
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppTheme.onSurface,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // === BUTTONS ===
            Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.surfaceVariant,
                        foregroundColor: AppTheme.onSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(cancelLabel),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Confirm
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.surfaceVariant,
                        foregroundColor: confirmColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Popup menu yang lebih modern dan konsisten
Future<String?> showStyledPopupMenu(
  BuildContext context, {
  required RelativeRect position,
  required List<StyledPopupItem> items,
}) {
  return showMenu<String>(
    context: context,
    position: position,
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    color: AppTheme.surface,
    shadowColor: Colors.black.withValues(alpha: 0.12),
    constraints: const BoxConstraints(minWidth: 180),
    items: items.map((item) {
      return PopupMenuItem<String>(
        value: item.value,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: item.iconBackground ?? item.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, size: 16, color: item.color),
            ),
            const SizedBox(width: 12),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: item.color,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

class StyledPopupItem {
  final String value;
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconBackground;

  const StyledPopupItem({
    required this.value,
    required this.icon,
    required this.label,
    this.color = AppTheme.onSurface,
    this.iconBackground,
  });
}

/// Generate styled popup menu items for PopupMenuButton
List<PopupMenuItem<String>> buildStyledPopupItems(List<StyledPopupItem> items) {
  return items.map((item) {
    return PopupMenuItem<String>(
      value: item.value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.iconBackground ?? item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 16, color: item.color),
          ),
          const SizedBox(width: 12),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: 'Google Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: item.color,
            ),
          ),
        ],
      ),
    );
  }).toList();
}
