import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';

class SourceLinkWidget extends StatelessWidget {
  final String title;
  final String publisher;
  final String url;
  final bool isVideo;

  const SourceLinkWidget({
    super.key,
    required this.title,
    required this.publisher,
    required this.url,
    this.isVideo = false,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error membuka link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (url.isNotEmpty) {
              _launchUrl(context, url);
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
                Icon(
                  isVideo ? LucideIcons.playCircle : LucideIcons.externalLink,
                  size: 20,
                  color: isVideo ? Colors.red : AppTheme.primaryGreen,
                ),
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
}
