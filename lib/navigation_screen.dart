import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_indicator.dart';
import '../services/permission_service.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  NavStatus _status = NavStatus.starting;
  String _statusLabel = 'Requesting camera permission…';
  String _lastAnnouncement = '';
  Timer? _demoTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await PermissionService.ensureCameraPermission();

    if (!mounted) return;

    if (!granted) {
      setState(() {
        _status = NavStatus.error;
        _statusLabel = 'Camera permission denied. Enable it in system settings.';
      });
      return;
    }

    setState(() {
      _status = NavStatus.running;
      _statusLabel = 'Camera active — scanning for obstacles';
    });

    // --- Placeholder loop -------------------------------------------------
    // Phase 2 replaces this with: camera frame -> YOLO detection ->
    // distance/direction estimate -> here. Kept as a fake timer for now so
    // the UI, layout, and screen-reader announcements can be built and
    // tested before the detection pipeline exists.
    _demoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      setState(() {
        _lastAnnouncement = 'Chair ahead, two meters, move left';
      });
    });
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    super.dispose();
  }

  void _stop() {
    _demoTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatusIndicator(status: _status, label: _statusLabel),
              const SizedBox(height: 20),
              Expanded(child: _buildPreviewArea(context)),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: 'Stop navigation and return home',
                child: ElevatedButton.icon(
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.danger,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder for the live camera feed (Phase 2 swaps this container
  /// for a `CameraPreview` widget) plus a caption area showing the most
  /// recent spoken announcement — useful for demoing/testing without
  /// audio, and doubles as an on-screen transcript for hard-of-hearing users.
  Widget _buildPreviewArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Live camera preview\n(connected in Phase 2)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 32),
          if (_lastAnnouncement.isNotEmpty)
            Semantics(
              liveRegion: true,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _lastAnnouncement,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: AppTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
