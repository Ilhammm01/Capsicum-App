import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/theme.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> disease;

  const DiseaseDetailScreen({super.key, required this.disease});

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  List<String> _images = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final penyakit = widget.disease;
    final String diseaseId = penyakit['id'] ?? '';

    try {
      final manifestContent =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssets = manifestContent.listAssets();

      final imagePaths = allAssets
          .where((String key) =>
              key.startsWith('assets/images/$diseaseId/') &&
              key.endsWith('.webp'))
          .toList();

      if (mounted) {
        setState(() {
          _images = imagePaths.isNotEmpty
              ? imagePaths
              : ['assets/images/$diseaseId.webp'];
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _images = ['assets/images/$diseaseId.webp'];
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuka link: $e')),
        );
      }
    }
  }

  Widget _buildSourceLink(dynamic source, {bool isVideo = false}) {
    final title = source['title'] ?? 'Tidak ada judul';
    final publisher = source['publisher'] ?? 'Tidak diketahui';
    final url = source['url'] ?? '';

    final isTikTok = url.toLowerCase().contains('tiktok.com');
    final isYouTube = url.toLowerCase().contains('youtube.com') ||
        url.toLowerCase().contains('youtu.be');

    Widget iconWidget;
    if (isTikTok) {
      // Periksa apakah asset tersedia, gunakan icon fallback jika error di luar
      iconWidget = SvgPicture.asset('assets/icons/tiktok_icon.svg',
          width: 20, height: 20);
    } else if (isVideo && isYouTube) {
      iconWidget = SvgPicture.asset('assets/icons/youtube_icon.svg',
          width: 20, height: 20);
    } else if (isVideo) {
      iconWidget =
          const Icon(LucideIcons.playCircle, size: 20, color: Colors.red);
    } else {
      iconWidget = const Icon(LucideIcons.bookOpenText,
          size: 20, color: AppTheme.primaryGreen);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (url.isNotEmpty) {
              _launchUrl(url);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.divider),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        publisher,
                        style: const TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final penyakit = widget.disease;
    final nama = penyakit['name_id'] ?? penyakit['nama'] ?? 'Tidak diketahui';
    final labelModel = penyakit['label_model'] ?? 'Unknown Type';
    final deskripsi = penyakit['description'] ??
        penyakit['deskripsi'] ??
        'Tidak ada deskripsi.';
    final listSymptoms = (penyakit['symptoms'] as List<dynamic>?) ?? [];
    final listRekomendasi =
        (penyakit['care_recommendations'] as List<dynamic>?) ??
            (penyakit['rekomendasi'] as List<dynamic>?) ??
            [];
    final listSources = (penyakit['sources'] as List<dynamic>?) ?? [];
    final listVideoSources =
        (penyakit['video_sources'] as List<dynamic>?) ?? [];

    // Menggunakan _images yang sudah diload dari AssetManifest
    final List<String> images = _images;

    return Scaffold(
      backgroundColor: Colors.black, // Untuk border di atas dan belakang image
      body: Stack(
        children: [
          // Basic Image Slider
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemCount: images.isEmpty ? 1 : images.length,
                  itemBuilder: (context, index) {
                    if (_isLoadingImages) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final currentImage = images.isNotEmpty ? images[index] : '';
                    return Image.asset(
                      currentImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceVariant,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.image,
                                size: 40,
                                color: AppTheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Gambar tidak tersedia\n$currentImage',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Google Sans',
                                  fontSize: 12,
                                  color: AppTheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                // Indicator dots
                if (images.length > 1)
                  Positioned(
                    bottom: 32, // Angkat sedikit ke atas sebelum sheet menutupi
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentImageIndex == index ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Draggable Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.55, // 55% of the screen
            minChildSize: 0.55,
            maxChildSize: 0.95, // can drag to almost top
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
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

                    // Titles
                    Text(
                      nama,
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labelModel, // ex: Capsicum Annuum Cowhorn Peppers
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 16,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      deskripsi,
                      style: const TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 14,
                        height: 1.6,
                        color: AppTheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),

                    // Symptoms if any
                    if (listSymptoms.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Gejala:',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...listSymptoms.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'Google Sans',
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],

                    // Recommendations
                    if (listRekomendasi.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Rekomendasi Penanganan:',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...listRekomendasi.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: CircleAvatar(
                                    radius: 3,
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.toString(),
                                    style: const TextStyle(
                                      fontFamily: 'Google Sans',
                                      fontSize: 14,
                                      height: 1.5,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],

                    // Sources
                    if (listSources.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Sumber Informasi:',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...listSources.map((source) => _buildSourceLink(source)),
                    ],

                    // Videos
                    if (listVideoSources.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Video Tutorial:',
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...listVideoSources.map(
                          (source) => _buildSourceLink(source, isVideo: true)),
                    ],
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
}
