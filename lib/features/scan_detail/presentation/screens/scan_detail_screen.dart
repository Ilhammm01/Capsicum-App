import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../shared_data/disease_reference/disease_info_repository.dart';
import '../../../../shared_data/widgets/confirm_dialog.dart';
import '../../../history/data/repositories/history_repository.dart';
import '../widgets/disease_summary_card.dart';
import '../widgets/disease_list_tile.dart';
import '../widgets/recommendation_list_tile.dart';
import '../widgets/recommended_products_widget.dart';
import '../widgets/source_links_widget.dart';

class ScanDetailScreen extends ConsumerStatefulWidget {
  final ScanDetailArgs? args;

  const ScanDetailScreen({super.key, this.args});

  @override
  ConsumerState<ScanDetailScreen> createState() => _ScanDetailScreenState();
}

class _ScanDetailScreenState extends ConsumerState<ScanDetailScreen> {
  final _diseaseRepo = DiseaseInfoRepository();
  bool _repoLoaded = false;
  int _selectedDiseaseIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadDiseaseRepo();
  }

  Future<void> _loadDiseaseRepo() async {
    await _diseaseRepo.loadIfNeeded();
    if (mounted) setState(() => _repoLoaded = true);
  }

  @override
  void dispose() {
    ref.read(ttsServiceProvider).stop();
    super.dispose();
  }

  Future<void> _deleteScan(ScanDetailArgs args) async {
    final confirmed = await showConfirmDialog(
      context,
      icon: LucideIcons.trash2,
      iconColor: AppTheme.severityBerat,
      iconBackground: AppTheme.severityBerat.withValues(alpha: 0.1),
      title: 'Hapus Hasil Scan?',
      message: 'Data scan dan foto ini akan dihapus secara permanen.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
    );
    if (confirmed == true && mounted) {
      if (args.imagePath.isNotEmpty) {
        final f = File(args.imagePath);
        if (f.existsSync()) f.deleteSync();
      }
      final box = HistoryRepository.box;
      if (args.historyKey != null) {
        box.delete(args.historyKey);
      }
      Navigator.of(context).pop();
    }
  }

  void _showVoiceSelectionSheet() {
    final tts = ref.read(ttsServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final current = tts.currentVoiceType;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilihan Karakter Suara',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                            fontFamily: 'Google Sans',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih jenis suara asisten untuk pembacaan hasil deteksi:',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...TtsVoiceType.values.map((v) {
                      final isSelected = v == current;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                              : AppTheme.surfaceVariant.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          leading: Icon(
                            v == TtsVoiceType.female
                                ? LucideIcons.smile
                                : v == TtsVoiceType.male
                                    ? LucideIcons.userCheck
                                    : LucideIcons.volume2,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.onSurfaceVariant,
                          ),
                          title: Text(
                            v.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : AppTheme.onSurface,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.playCircle, size: 22),
                            color: AppTheme.primaryGreen,
                            tooltip: 'Putar Contoh',
                            onPressed: () {
                              tts.playSample(v);
                            },
                          ),
                          onTap: () async {
                            await tts.setVoiceType(v);
                            setModalState(() {});
                            if (mounted) setState(() {});
                            tts.playSample(v);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detail Scan'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (args != null) ...[
            IconButton(
              icon: const Icon(LucideIcons.volume2, size: 22),
              color: AppTheme.primaryGreen,
              tooltip: 'Dengarkan Hasil Suara',
              onPressed: () {
                ref.read(ttsServiceProvider).speakDetectionResult(
                      diseaseIds: args.detectedDiseaseIds,
                      severityLevel: args.severityLevel,
                      diseaseConfidences: args.diseaseConfidences,
                      averageConfidence: args.averageConfidence,
                    );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.slidersHorizontal, size: 20),
              color: AppTheme.onSurfaceVariant,
              tooltip: 'Pilih Karakter Suara',
              onPressed: _showVoiceSelectionSheet,
            ),
          ],
          if (args != null && args.historyKey != null)
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 22),
              color: AppTheme.severityBerat,
              tooltip: 'Hapus Data Scan',
              onPressed: () => _deleteScan(args),
            ),
        ],
      ),
      body: args == null ? _buildEmptyState() : _buildContent(args),
    );
  }

  Widget _buildContent(ScanDetailArgs args) {
    final diseases = _repoLoaded
        ? _diseaseRepo.findByIds(args.detectedDiseaseIds)
        : <DiseaseInfo>[];

    // Total bounding box detections
    final totalDetections = args.diseaseDetectionCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === GAMBAR SCAN ===
          _buildScanImage(args.imagePath),
          const SizedBox(height: 16),

          if (args.detectedDiseaseIds.isNotEmpty) ...[
            // === METADATA ===
            _buildMetadata(args),
            const SizedBox(height: 16),

            // === SUMMARY CARD ===
            DiseaseSummaryCard(
              diseaseCount: args.detectedDiseaseIds.length,
              severityLevel: args.severityLevel,
              confidence: args.averageConfidence,
              totalDetections: totalDetections > 0 ? totalDetections : null,
            ),
            const SizedBox(height: 20),
          ],

          // === JENIS PENYAKIT ===
          if (diseases.isNotEmpty) ...[
            if (diseases.length > 1) ...[
              _buildDiseaseTabs(diseases),
              const SizedBox(height: 24),
            ],
            Builder(
              builder: (context) {
                final activeIdx = _selectedDiseaseIndex < diseases.length
                    ? _selectedDiseaseIndex
                    : 0;
                final d = diseases[activeIdx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Informasi Penyakit (${d.nameId})'),
                    const SizedBox(height: 12),
                    DiseaseListTile(
                      disease: d,
                      confidences: args.diseaseAllConfidences[d.id] ??
                          (args.diseaseConfidences[d.id] != null
                              ? [args.diseaseConfidences[d.id]!]
                              : null),
                      detectionCount: args.diseaseDetectionCounts[d.id],
                    ),
                    const SizedBox(height: 20),

                    // === REKOMENDASI ===
                    if (d.type != 'healthy') ...[
                      _SectionHeader(title: 'Rekomendasi Perawatan'),
                      const SizedBox(height: 12),
                      RecommendationListTile(disease: d),
                      const SizedBox(height: 24),
                    ],

                    // === PRODUK REKOMENDASI ===
                    if (d.produk.isNotEmpty) ...[
                      RecommendedProductsWidget(
                        products: d.produk.toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // === SUMBER REFERENSI & VIDEO ===
                    SourceLinksWidget(diseases: [d]),
                  ],
                );
              },
            ),
          ] else if (!_repoLoaded) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
          ] else ...[
            _buildNoDiseaseInfo(args),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDiseaseTabs(List<DiseaseInfo> diseases) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(diseases.length, (index) {
          final isSelected = _selectedDiseaseIndex == index;
          final d = diseases[index];
          IconData tabIcon;
          switch (d.type) {
            case 'healthy':
              tabIcon = LucideIcons.leaf;
              break;
            case 'viral':
              tabIcon = LucideIcons.bug;
              break;
            case 'bacterial':
              tabIcon = LucideIcons.activity;
              break;
            default:
              tabIcon = LucideIcons.triangleAlert;
              break;
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDiseaseIndex = index;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.divider,
                ),
                boxShadow: const [],
              ),
              child: Row(
                children: [
                  Icon(
                    tabIcon,
                    size: 16,
                    color:
                        isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    d.nameId,
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildScanImage(String imagePath) {
    if (imagePath.isEmpty || !File(imagePath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Container(
            color: AppTheme.surfaceVariant,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.cameraOff,
                  size: 48,
                  color: AppTheme.onSurfaceVariant,
                ),
                SizedBox(height: 12),
                Text(
                  'Gambar tidak ditemukan',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(LucideIcons.x,
                        color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            cacheWidth: 1080,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(ScanDetailArgs args) {
    final latlongStr = (args.latitude != null && args.longitude != null)
        ? LocationService.formatLatLong(args.latitude!, args.longitude!)
        : '-';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _MetaRow(
            icon: LucideIcons.calendarClock,
            label: DateFormatter.formatFull(args.scannedAt),
          ),
          if (args.locationName != null) ...[
            const SizedBox(height: 8),
            _MetaRow(
              icon: LucideIcons.mapPinned,
              label: args.locationName!,
            ),
          ],
          const SizedBox(height: 8),
          _MetaRow(icon: LucideIcons.compass, label: latlongStr),
        ],
      ),
    );
  }

  Widget _buildNoDiseaseInfo(ScanDetailArgs args) {
    if (args.detectedDiseaseIds.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getSeverityBgColor('ringan'),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.circleCheck,
                color: AppTheme.severityRingan, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak terdeteksi penyakit pada daun cabai besar ini.',
                style: TextStyle(
                  color: AppTheme.primaryGreenDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'ID Penyakit: ${args.detectedDiseaseIds.join(", ")}\n'
        'Informasi detail belum tersedia. Pastikan disease_info.json sudah diisi.',
        style: const TextStyle(color: AppTheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
        child: Text(
          'Tidak ada data scan.',
          style: TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        fontFamily: 'Google Sans',
        color: AppTheme.onSurface,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
              fontFamily: 'Google Sans',
            ),
          ),
        ),
      ],
    );
  }
}
