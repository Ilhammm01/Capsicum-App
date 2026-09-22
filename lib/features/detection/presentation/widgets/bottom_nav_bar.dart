import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CameraBottomNavBar extends StatelessWidget {
  final VoidCallback onPhoto;
  final VoidCallback onScan;
  final VoidCallback onHistory;
  final bool isSaving;

  const CameraBottomNavBar({
    super.key,
    required this.onPhoto,
    required this.onScan,
    required this.onHistory,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
            vertical: 8), // Padding dikecilkan agar nav tidak terlalu tinggi
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // === CAPTURE ===
            _NavButton(
              icon: LucideIcons.scan,
              label: 'Capture',
              onTap: isSaving ? null : onPhoto,
              isLoading: isSaving,
            ),

            // === SCAN (tombol utama) ===
            _ScanButton(onTap: onScan),

            // === HISTORY ===
            _NavButton(
              icon: LucideIcons.clock,
              label: 'History',
              onTap: onHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _NavButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey.shade700,
                    ),
                  )
                : Icon(icon,
                    color: Colors.grey.shade700,
                    size: 24), // Ikon dikecilkan sedikit (dari 26 ke 24)
            const SizedBox(height: 3), // Spasi dikecilkan
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 10.5,
                fontFamily: 'Google Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 65, // Lingkaran tombol utama dikecilkan dari 60 ke 52
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF03A103), // rgba(3, 161, 3, 1) (0% - 50%)
                  Color(0xFF03A103), // rgba(3, 161, 3, 1) at 50%
                  Color(0xFFCFBB06), // rgba(207, 187, 6, 1) at 100%
                ],
                stops: [
                  0.0,
                  0.5,
                  1.0,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              LucideIcons.scanSearch,
              color: Colors.white,
              size: 34, // Ikon kamera disesuaikan dengan ukuran lingkaran
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Scan',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 10.5,
              fontFamily: 'Google Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
