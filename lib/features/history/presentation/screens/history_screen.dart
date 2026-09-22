import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/scan_history_tab.dart';
import '../widgets/gallery_tab.dart';
import '../../../../app/theme.dart';
import 'information_hub_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _selectedTab = 0;

  void _switchTab(int index) {
    if (index == _selectedTab) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            fontFamily: 'Google Sans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bookMarked, size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InformationHubScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // === SEGMENTED TAB CONTROL ===
          _buildTabBar(),

          // === CONTENT dengan cross-fade + subtle slide ===
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                final isEntering = child.key == ValueKey(_selectedTab);
                final slideAnim = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                // Enter and exit slide in opposite directions based on
                // which tab we're moving towards, so the transition feels
                // directional instead of a plain fade.
                final beginOffset = isEntering
                    ? Offset(_selectedTab == 1 ? 0.06 : -0.06, 0)
                    : Offset.zero;
                return FadeTransition(
                  opacity: animation,
                  child: isEntering
                      ? SlideTransition(
                          position: Tween<Offset>(
                            begin: beginOffset,
                            end: Offset.zero,
                          ).animate(slideAnim),
                          child: child,
                        )
                      : child,
                );
              },
              child: _selectedTab == 0
                  ? const ScanHistoryTab(key: ValueKey(0))
                  : const GalleryTab(key: ValueKey(1)),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  //  Tab bar — single sliding pill indicator behind
  //  the tabs, animated with AnimatedAlign so it
  //  glides smoothly from one side to the other
  //  instead of each tab fading its own background.
  // =============================================
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.divider, width: 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / 2;
            return Stack(
              children: [
                // Sliding highlighted pill
                AnimatedAlign(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: _selectedTab == 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    width: segmentWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap targets + labels, sitting on top of the pill
                Row(
                  children: [
                    _SegmentedTab(
                      label: 'Scan',
                      icon: LucideIcons.scanLine,
                      selected: _selectedTab == 0,
                      onTap: () => _switchTab(0),
                    ),
                    _SegmentedTab(
                      label: 'Gallery',
                      icon: LucideIcons.image,
                      selected: _selectedTab == 1,
                      onTap: () => _switchTab(1),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================
//  Tab button — transparent tap target with a
//  gentle press-scale for tactile feedback. The
//  pill background now lives in the parent Stack,
//  so this widget only handles label/icon state.
// =============================================
class _SegmentedTab extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentedTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SegmentedTab> createState() => _SegmentedTabState();
}

class _SegmentedTabState extends State<_SegmentedTab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final labelColor =
        widget.selected ? AppTheme.onSurface : AppTheme.onSurfaceVariant;
    final fontWeight = widget.selected ? FontWeight.w600 : FontWeight.w500;

    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: SizedBox(
            height: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    widget.icon,
                    key: ValueKey(widget.selected),
                    size: 16,
                    color: labelColor,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  style: TextStyle(
                    fontFamily: 'Google Sans',
                    fontSize: 13,
                    fontWeight: fontWeight,
                    color: labelColor,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
