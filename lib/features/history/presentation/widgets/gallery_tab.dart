import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared_data/widgets/confirm_dialog.dart';

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  List<File> _images = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    final dir = await getApplicationDocumentsDirectory();
    final scanDir = Directory('${dir.path}/capsicum_captures');
    if (!scanDir.existsSync()) {
      if (mounted) {
        setState(() {
          _images = [];
          _loading = false;
        });
      }
      return;
    }
    final files = scanDir.listSync().whereType<File>().where((f) {
      final ext = f.path.toLowerCase();
      return ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.png');
    }).toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (mounted) {
      setState(() {
        _images = files;
        _loading = false;
      });
    }
  }

  Future<void> _downloadImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = 'capsicum_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: fileName,
        skipIfExists: false,
      );
      if (!mounted) return;
      final success = result.isSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Foto disimpan ke galeri' : 'Gagal menyimpan foto'),
          backgroundColor:
              success ? AppTheme.primaryGreen : AppTheme.severityBerat,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
    }
  }

  Future<void> _deleteImage(File file) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: LucideIcons.trash2,
      iconColor: AppTheme.severityBerat,
      iconBackground: AppTheme.severityBerat.withValues(alpha: 0.1),
      title: 'Hapus Foto?',
      message: 'Foto ini akan dihapus permanen dan tidak dapat dikembalikan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
    );
    if (confirmed == true) {
      await file.delete();
      _loadImages();
    }
  }

  void _openFullscreen(File file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(
          file: file,
          onDownload: () => _downloadImage(file),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      );
    }
    if (_images.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadImages,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.85,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) {
          final file = _images[index];
          return _GalleryCard(
            file: file,
            onTap: () => _openFullscreen(file),
            onDownload: () => _downloadImage(file),
            onDelete: () => _deleteImage(file),
          );
        },
      ),
    );
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
              LucideIcons.images,
              size: 32,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada foto tersimpan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
              fontFamily: 'Google Sans',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tekan tombol Capture di kamera\nuntuk menyimpan foto.',
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
// Gallery Card — same style as Scan Card
// ============================================================
class _GalleryCard extends StatelessWidget {
  final File file;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _GalleryCard({
    required this.file,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final modTime = file.lastModifiedSync();

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // === THUMBNAIL ===
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // === INFO ROW ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormatter.formatRelative(modTime),
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(
                          0xFF6B7280), // Neutral gray matching the reference
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'download') onDownload();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => buildStyledPopupItems([
                      const StyledPopupItem(
                        value: 'download',
                        icon: LucideIcons.download,
                        label: 'Download',
                        color: AppTheme.primaryGreen,
                      ),
                      const StyledPopupItem(
                        value: 'delete',
                        icon: LucideIcons.trash2,
                        label: 'Hapus',
                        color: AppTheme.severityBerat,
                      ),
                    ]),
                    icon: const Icon(LucideIcons.ellipsisVertical,
                        size: 18, color: Color(0xFF374151)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    color: AppTheme.surface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Fullscreen Image Viewer
// ============================================================
class _FullscreenImageViewer extends StatelessWidget {
  final File file;
  final VoidCallback onDownload;

  const _FullscreenImageViewer({
    required this.file,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.download, size: 22),
            tooltip: 'Download ke Galeri',
            onPressed: onDownload,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: Image.file(file),
        ),
      ),
    );
  }
}
