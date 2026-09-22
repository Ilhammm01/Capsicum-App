import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';

// ============================================================
// Model data bahan aktif
// ============================================================
class IngredientInfo {
  final String id;
  final String name;
  final String type;
  final String
      typeColor; // fungicide | insecticide | bactericide | biological | organic
  final String mechanism;
  final List<String> targets;
  final String application;
  final String dosage;
  final String safety;
  final String note;

  const IngredientInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.typeColor,
    required this.mechanism,
    required this.targets,
    required this.application,
    required this.dosage,
    required this.safety,
    required this.note,
  });

  factory IngredientInfo.fromJson(Map<String, dynamic> j) => IngredientInfo(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String? ?? '',
        typeColor: j['type_color'] as String? ?? 'fungicide',
        mechanism: j['mechanism'] as String? ?? '',
        targets: (j['targets'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        application: j['application'] as String? ?? '',
        dosage: j['dosage'] as String? ?? '',
        safety: j['safety'] as String? ?? '',
        note: j['note'] as String? ?? '',
      );
}

// ============================================================
// Repository (singleton) untuk bahan aktif
// ============================================================
class IngredientRepository {
  static final IngredientRepository _i = IngredientRepository._();
  factory IngredientRepository() => _i;
  IngredientRepository._();

  Map<String, IngredientInfo>? _cache;

  Future<void> loadIfNeeded() async {
    if (_cache != null) return;
    final raw =
        await rootBundle.loadString('assets/data/active_ingredients.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data['ingredients'] as List<dynamic>)
        .map((e) => IngredientInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    _cache = {for (final i in list) i.name.toLowerCase(): i};
  }

  /// Cari dengan nama bahan aktif (case-insensitive, partial match)
  IngredientInfo? findByName(String name) {
    if (_cache == null) return null;
    final key = name.toLowerCase().trim();
    // cek exact
    if (_cache!.containsKey(key)) return _cache![key];
    // cek partial
    for (final entry in _cache!.entries) {
      if (entry.key.contains(key) || key.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Ambil semua bahan aktif
  List<IngredientInfo> getAll() {
    return _cache?.values.toList() ?? [];
  }
}

// ============================================================
// Warna & ikon tiap kategori
// ============================================================
Color _typeColor(String typeColor) {
  switch (typeColor) {
    case 'insecticide':
      return const Color(0xFFE65100);
    case 'bactericide':
      return const Color(0xFF1565C0);
    case 'biological':
      return const Color(0xFF2E7D32);
    case 'organic':
      return const Color(0xFF558B2F);
    default: // fungicide
      return const Color(0xFF6A1B9A);
  }
}

IconData _typeIcon(String typeColor) {
  switch (typeColor) {
    case 'insecticide':
      return LucideIcons.bug;
    case 'bactericide':
      return LucideIcons.shield;
    case 'biological':
      return LucideIcons.leaf;
    case 'organic':
      return LucideIcons.sprout;
    default:
      return LucideIcons.flaskConical;
  }
}

String _typeLabel(String typeColor) {
  switch (typeColor) {
    case 'insecticide':
      return 'INSEKTISIDA';
    case 'bactericide':
      return 'BAKTERISIDA';
    case 'biological':
      return 'AGEN HAYATI';
    case 'organic':
      return 'ORGANIK';
    default:
      return 'FUNGISIDA';
  }
}

// ============================================================
// Fungsi pembuka bottom sheet
// ============================================================
void showIngredientDetail(BuildContext context, String ingredientName) async {
  final repo = IngredientRepository();
  await repo.loadIfNeeded();
  final info = repo.findByName(ingredientName);

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _IngredientDetailSheet(
      ingredientName: ingredientName,
      info: info,
    ),
  );
}

// ============================================================
// Widget Bottom Sheet
// ============================================================
class _IngredientDetailSheet extends StatelessWidget {
  final String ingredientName;
  final IngredientInfo? info;

  const _IngredientDetailSheet({
    required this.ingredientName,
    required this.info,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        info != null ? _typeColor(info!.typeColor) : AppTheme.primaryGreen;
    final icon =
        info != null ? _typeIcon(info!.typeColor) : LucideIcons.flaskConical;
    final label = info != null ? _typeLabel(info!.typeColor) : 'BAHAN AKTIF';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // Scrollable body
            Expanded(
              child: CustomScrollView(
                controller: scrollCtrl,
                slivers: [
                  // -- HEADER ILUSTRASI --
                  SliverToBoxAdapter(
                    child: _buildHeader(color, icon, label),
                  ),

                  // -- KONTEN --
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (info == null)
                          _buildUnknown()
                        else ...[
                          _buildSection(
                            icon: LucideIcons.microscope,
                            title: 'Mekanisme Kerja',
                            color: color,
                            child: Text(
                              info!.mechanism,
                              style: _bodyStyle,
                            ),
                          ),
                          _buildSection(
                            icon: LucideIcons.crosshair,
                            title: 'Target / OPT Sasaran',
                            color: color,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: info!.targets
                                  .map((t) => _buildBullet(t, color))
                                  .toList(),
                            ),
                          ),
                          _buildSection(
                            icon: LucideIcons.sprout,
                            title: 'Cara Aplikasi',
                            color: color,
                            child: Text(info!.application, style: _bodyStyle),
                          ),
                          _buildSection(
                            icon: LucideIcons.beaker,
                            title: 'Dosis Umum',
                            color: color,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.droplets,
                                      color: color, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(info!.dosage,
                                        style: _bodyStyle.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: color,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildSafetyBanner(info!.safety),
                          if (info!.note.isNotEmpty)
                            _buildNoteBanner(info!.note),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color, IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.04)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Google Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      info?.name ?? ingredientName,
                      style: TextStyle(
                        fontFamily: 'Google Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onSurface,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (info != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              height: 1,
              color: color.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              info!.type,
              style: TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 13,
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Google Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildBullet(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: _bodyStyle.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.triangleAlert,
                color: Color(0xFFE65100), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Keamanan & APD',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBF360C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      color: Color(0xFF5D4037),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBanner(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info,
                color: AppTheme.primaryGreen, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Penting',
                    style: TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Google Sans',
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknown() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Center(
        child: Column(
          children: [
            const Icon(LucideIcons.searchX,
                size: 48, color: AppTheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Informasi detail untuk "$ingredientName"\nbelum tersedia dalam basis data.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Google Sans',
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontFamily: 'Google Sans',
    fontSize: 14,
    color: AppTheme.onSurfaceVariant,
    height: 1.5,
  );
}
