import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../providers/detection_providers.dart';
import '../widgets/detection_overlay_widget.dart';
import '../widgets/detection_info_panel.dart';

import '../widgets/bottom_nav_bar.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/image_capture_service.dart';
import '../../../../features/history/data/models/scan_history_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  bool _permissionDenied = false;
  bool _cameraInitialized = false;
  bool _torchOn = false;
  bool _isSaving = false;
  bool _showCaptureOverlay = false;
  Completer<void>? _captureCompleter;

  final GlobalKey _cameraKey = GlobalKey();
  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAll();
  }

  Future<void> _initAll() async {
    final result = await PermissionService.requestAll();
    if (!mounted) return;

    if (!result.cameraGranted) {
      setState(() => _permissionDenied = true);
      return;
    }

    await _initCamera();
    await _initLocation();
    _startInference();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset
            .medium, // ~640×480 — cukup untuk 640 model, lebih ringan di CPU
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _cameraInitialized = true);

      // Mulai image stream — simpan frame langsung di-pass jika butuh inference
      await _controller!.startImageStream((frame) {
        if (_captureCompleter != null && !_captureCompleter!.isCompleted) {
          final completer = _captureCompleter;
          _runInferenceOnFrame(frame).then((_) {
            if (!completer!.isCompleted) completer.complete();
          });
        }
      });

      // Update preview size for severity calculation
      final previewSize = _controller?.value.previewSize;
      if (previewSize != null) {
        ref.read(previewSizeProvider.notifier).state = previewSize;
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _initLocation() async {
    // Pastikan GPS + izin siap; tampilkan dialog jika GPS mati
    final status = await LocationService.ensureReady();

    if (status == LocationServiceStatus.serviceDisabled) {
      if (mounted) await _showGpsDisabledDialog();
      final retry = await LocationService.ensureReady();
      if (retry != LocationServiceStatus.ready) return;
    } else if (status != LocationServiceStatus.ready) {
      // permissionDenied / permissionDeniedForever — skip
      return;
    }

    // Subscribe ke stream posisi:
    // - Langsung emit last-known (instan) jika tersedia
    // - Kemudian terus emit posisi GPS baru secara otomatis
    _locationSub?.cancel();
    _locationSub = LocationService.positionStream().listen(
      (pos) async {
        if (!mounted) return;
        ref.read(currentLocationProvider.notifier).state = pos;
        // Geocoding di-fire-and-forget agar tidak memblokir update posisi
        LocationService.getLocationName(pos.latitude, pos.longitude).then(
          (name) {
            if (mounted && name != null) {
              ref.read(currentLocationNameProvider.notifier).state = name;
            }
          },
        );
      },
      onError: (e) => debugPrint('[Location stream] error: $e'),
      cancelOnError: false, // jangan hentikan stream karena satu error
    );
  }

  /// Dialog minta user mengaktifkan GPS di Settings perangkat
  Future<void> _showGpsDisabledDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(LucideIcons.mapPin, color: AppTheme.primaryGreen, size: 22),
            const SizedBox(width: 10),
            const Text(
              'Lokasi Tidak Aktif',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'Aktifkan GPS/Lokasi perangkat agar data koordinat dapat disimpan bersama hasil scan cabai besar Anda.',
          style: TextStyle(color: AppTheme.onSurfaceVariant, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Lewati',
              style: TextStyle(color: AppTheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.settings, size: 16),
            label: const Text('Buka Pengaturan GPS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await LocationService.openGpsSettings();
            },
          ),
        ],
      ),
    );
  }

  void _showTipsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tips Diagnosis',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Google Sans',
                ),
              ),
              const SizedBox(height: 24),
              _buildTipItem(
                '1.',
                'Mendekatlah ke tanaman dan pastikan gambar kerusakan tanaman cabai besar tersebut masuk ke dalam bingkai layar.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                '2.',
                'Pastikan kamera difokuskan dengan benar pada kerusakan tanaman.',
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                '3.',
                'Pastikan tanaman terlihat jelas dan tidak terlalu gelap atau terang.',
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Mengerti',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: AppTheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _startInference() async {
    final repo = ref.read(inferenceRepoProvider);
    await repo.loadModel();
  }

  Future<void> _runInferenceOnFrame(CameraImage frame) async {
    if (!_cameraInitialized || _controller == null) return;

    try {
      final repo = ref.read(inferenceRepoProvider);

      final (results, _) = await repo.runInference(
        cameraImage: frame,
        imageWidth: _controller!.description.sensorOrientation == 90 ||
                _controller!.description.sensorOrientation == 270
            ? frame.height
            : frame.width,
        imageHeight: _controller!.description.sensorOrientation == 90 ||
                _controller!.description.sensorOrientation == 270
            ? frame.width
            : frame.height,
        sensorOrientation: _controller!.description.sensorOrientation,
      );

      if (mounted) {
        ref.read(detectionResultsProvider.notifier).state = results;
        final rotated = _controller!.description.sensorOrientation == 90 ||
            _controller!.description.sensorOrientation == 270;
        ref.read(previewFrameSizeProvider.notifier).state = Size(
          (rotated ? frame.height : frame.width).toDouble(),
          (rotated ? frame.width : frame.height).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Inference error: $e');
    }
  }

  Future<void> _onCapturePhoto() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    _captureCompleter = Completer<void>();
    await _captureCompleter!.future;
    _captureCompleter = null;

    // Wait for Flutter to paint the bounding boxes onto the RepaintBoundary
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 50));

    setState(() => _showCaptureOverlay = true);

    // Capture goes to capsicum_captures exclusively (Gallery tab)
    final path = await ImageCaptureService.captureAndSave(
      _cameraKey,
      directoryName: 'capsicum_captures',
    );

    // Clear detection results immediately after capture so camera screen is clean
    ref.read(detectionResultsProvider.notifier).state = [];

    if (mounted) {
      setState(() {
        _showCaptureOverlay = false;
        _isSaving = false;
      });
    }

    if (path == null) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Foto tersimpan ke Galeri',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 140,
            left: 32,
            right: 32,
          ),
          dismissDirection: DismissDirection.up,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _onScanPressed() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    _captureCompleter = Completer<void>();
    await _captureCompleter!.future;
    _captureCompleter = null;

    // Read detection data BEFORE capture
    final severity = ref.read(severityLevelProvider);
    final avgConf = ref.read(avgConfidenceProvider);
    final diseaseIds = ref.read(detectedDiseaseIdsProvider);
    final diseaseConfs = ref.read(perDiseaseConfidenceProvider);
    final diseaseCounts = ref.read(perDiseaseCountProvider);
    final loc = ref.read(currentLocationProvider);
    final locName = ref.read(currentLocationNameProvider);

    // Wait for Flutter to paint the bounding boxes onto the RepaintBoundary
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 50));

    setState(() => _showCaptureOverlay = true);

    // Capture RepaintBoundary — bounding boxes are now painted inside it
    final path = await ImageCaptureService.captureAndSave(
      _cameraKey,
      directoryName: 'capsicum_scans',
    );

    // Clear detection results immediately after capture so camera screen is clean
    ref.read(detectionResultsProvider.notifier).state = [];

    if (mounted) {
      setState(() {
        _showCaptureOverlay = false;
        _isSaving = false;
      });
    }

    if (path == null) return;

    final entry = ScanHistoryModel(
      imagePath: path,
      scannedAt: DateTime.now(),
      detectedDiseaseIds: diseaseIds,
      severityLevel: severity,
      latitude: loc?.latitude,
      longitude: loc?.longitude,
      locationName: locName,
      averageConfidence: avgConf,
      diseaseConfidences: diseaseConfs,
      diseaseDetectionCounts: diseaseCounts,
    );
    final historyKey = await HistoryRepository.addScan(entry);

    if (mounted) {
      context.pushNamed(
        'scanDetail',
        extra: ScanDetailArgs(
          historyKey: historyKey,
          imagePath: path,
          detectedDiseaseIds: diseaseIds,
          severityLevel: severity,
          averageConfidence: avgConf,
          scannedAt: DateTime.now(),
          latitude: loc?.latitude,
          longitude: loc?.longitude,
          locationName: locName,
          diseaseConfidences: diseaseConfs,
          diseaseDetectionCounts: diseaseCounts,
        ),
      );
    }
  }

  void _onHistoryPressed() {
    context.pushNamed('history');
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_cameraInitialized) return;
    setState(() => _torchOn = !_torchOn);
    await _controller!.setFlashMode(_torchOn ? FlashMode.torch : FlashMode.off);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App masuk background — hentikan stream & inference
      _cameraInitialized = false;
      _controller?.stopImageStream().catchError((_) {});
      _controller?.dispose();
      _controller = null;
      // Hentikan location stream saat app ke background
      _locationSub?.cancel();
      _locationSub = null;
    } else if (state == AppLifecycleState.resumed) {
      // App kembali ke foreground — init ulang kamera + restart inference + lokasi
      _initCamera().then((_) {
        if (mounted && _cameraInitialized) {
          _startInference();
          _initLocation(); // re-subscribe stream lokasi
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSub?.cancel();
    _controller?.stopImageStream().catchError((_) {});
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) return _buildPermissionDenied();
    if (!_cameraInitialized) return _buildLoading();

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // === CAMERA PREVIEW + OVERLAY ===
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  key: _cameraKey,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCameraPreview(),
                      // === Bounding Boxes - Real-time ===
                      Consumer(
                        builder: (context, ref, _) {
                          final results = ref.watch(detectionResultsProvider);
                          final frameSize = ref.watch(previewFrameSizeProvider);

                          return DetectionOverlayWidget(
                            results: results,
                            previewSize: frameSize,
                          );
                        },
                      ),
                      // === Detection Info Panel ===
                      Positioned(
                        left: 0,
                        right:
                            0, // Batasi lebar layar agar teks panjang bisa terbungkus/wrap ke bawah
                        bottom:
                            12, // Memberi jarak dari bagian layar paling bawah frame kamera
                        child: Consumer(
                          builder: (context, ref, _) {
                            final pos = ref.watch(currentLocationProvider);
                            final name = ref.watch(currentLocationNameProvider);
                            // Menggunakan DateTimeProvider atau sejenisnya, tapi DateTime.now() saat ditaruh di build
                            // akan update setiap kali rebuild (termasuk setiap kali deteksi muncul).
                            return DetectionInfoPanel(
                              currentTime: DateTime.now(),
                              latitude: pos?.latitude,
                              longitude: pos?.longitude,
                              locationName: name,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Shutter effect: overlay hitam selama capture berlangsung
                if (_showCaptureOverlay)
                  Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        LucideIcons.camera,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // === BOTTOM NAV BAR ===
          CameraBottomNavBar(
            isSaving: _isSaving,
            onPhoto: _onCapturePhoto,
            onScan: _onScanPressed,
            onHistory: _onHistoryPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    // Guard: controller must exist AND be fully initialized
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final size = controller.value.previewSize;
    if (size == null) return CameraPreview(controller);

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: isPortrait ? size.height : size.width,
          height: isPortrait ? size.width : size.height,
          child: CameraPreview(controller),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: IconButton(
          icon: Icon(
            _torchOn ? LucideIcons.zap : LucideIcons.zapOff,
            color: _torchOn ? Colors.yellow : Colors.white,
          ),
          onPressed: _toggleTorch,
        ),
      ),
      title: const Text(
        'Capsicum App',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Google Sans',
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.info, color: Colors.white, size: 22),
          onPressed: _showTipsDialog,
          tooltip: 'Tips Diagnosis',
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Consumer(
            builder: (context, ref, _) {
              final locationAsync = ref.watch(locationActiveProvider);
              final isActive = locationAsync.valueOrNull ?? false;
              return _LocationStatusDot(
                active: isActive,
                onTapWhenInactive: () => _showGpsDisabledDialog(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primaryGreen),
            SizedBox(height: 16),
            Text('Memuat kamera...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.cameraOff,
                size: 64,
                color: Colors.white38,
              ),
              const SizedBox(height: 24),
              const Text(
                'Izin Kamera Diperlukan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Aplikasi membutuhkan akses kamera untuk mendeteksi penyakit daun cabai besar.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: PermissionService.openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Buka Pengaturan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationStatusDot extends StatelessWidget {
  final bool active;
  final VoidCallback? onTapWhenInactive;

  const _LocationStatusDot({
    required this.active,
    this.onTapWhenInactive,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.primaryGreen : Colors.red;
    final dot = Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (!active && onTapWhenInactive != null) {
      return GestureDetector(
        onTap: onTapWhenInactive,
        child: Tooltip(
          message: 'Lokasi tidak aktif — ketuk untuk mengaktifkan',
          child: dot,
        ),
      );
    }
    return Tooltip(
      message: active ? 'Lokasi aktif' : 'Lokasi tidak aktif',
      child: dot,
    );
  }
}
