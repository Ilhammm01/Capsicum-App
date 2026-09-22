import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/theme.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';

/// Widget menampilkan link sumber referensi (jurnal & video) per penyakit
class SourceLinksWidget extends StatelessWidget {
  final List<DiseaseInfo> diseases;

  const SourceLinksWidget({super.key, required this.diseases});

  @override
  Widget build(BuildContext context) {
    // Kumpulkan semua sources (journal/official) dan video
    final allSources = <_SourceEntry>[];
    final allVideos = <_SourceEntry>[];

    for (final d in diseases) {
      for (final s in d.sources) {
        allSources.add(_SourceEntry(diseaseName: d.nama, source: s));
      }
      for (final v in d.videoSources) {
        allVideos.add(_SourceEntry(diseaseName: d.nama, source: v));
      }
    }

    if (allSources.isEmpty && allVideos.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === SUMBER REFERENSI ===
        if (allSources.isNotEmpty) ...[
          const Text(
            'Sumber Referensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Google Sans',
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Jurnal ilmiah dan sumber resmi terkait.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'Google Sans',
            ),
          ),
          const SizedBox(height: 12),
          ...allSources.map(
            (e) => _SourceTile(entry: e, isVideo: false),
          ),
          const SizedBox(height: 20),
        ],

        // === VIDEO ===
        if (allVideos.isNotEmpty) ...[
          const Text(
            'Video Tutorial',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Google Sans',
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Video pengendalian dan perawatan.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'Google Sans',
            ),
          ),
          const SizedBox(height: 12),
          ...allVideos.map(
            (e) => _SourceTile(entry: e, isVideo: true),
          ),
        ],
      ],
    );
  }
}

class _SourceEntry {
  final String diseaseName;
  final DiseaseSource source;
  const _SourceEntry({required this.diseaseName, required this.source});
}

class _SourceTile extends StatelessWidget {
  final _SourceEntry entry;
  final bool isVideo;

  const _SourceTile({required this.entry, required this.isVideo});

  Future<void> _openUrl(BuildContext context) async {
    final url = entry.source.url;
    if (url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri == null) return;

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = entry.source;
    final title = s.title;
    // Combine publisher and year for the subtitle like in DiseaseInfoScreen
    final publisher = s.year > 0 ? '${s.publisher} · ${s.year}' : s.publisher;

    final isTikTok = s.type.toLowerCase() == 'tiktok' ||
        s.url.toLowerCase().contains('tiktok.com');
    final isYouTube = isVideo &&
        !isTikTok &&
        (s.url.toLowerCase().contains('youtube.com') ||
            s.url.toLowerCase().contains('youtu.be') ||
            s.type.toLowerCase() == 'youtube');

    Widget iconWidget;
    if (isTikTok) {
      iconWidget = SvgPicture.asset('assets/icons/tiktok_icon.svg',
          width: 20, height: 20);
    } else if (isYouTube) {
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
          onTap: () => _openUrl(context),
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
                          height: 1.4,
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
}
