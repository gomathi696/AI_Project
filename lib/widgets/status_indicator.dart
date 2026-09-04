import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum NavStatus { idle, starting, running, error }

/// Shows the current pipeline status ("camera capturing frames",
/// "listening for obstacles", etc). Kept as its own widget because
/// Phase 2/3 will update this frequently from the detection loop —
/// isolating it avoids rebuilding the whole screen.
class StatusIndicator extends StatelessWidget {
  final NavStatus status;
  final String label;

  const StatusIndicator({
    super.key,
    required this.status,
    required this.label,
  });

  IconData get _icon {
    switch (status) {
      case NavStatus.idle:
        return Icons.pause_circle_outline;
      case NavStatus.starting:
        return Icons.hourglass_top;
      case NavStatus.running:
        return Icons.podcasts;
      case NavStatus.error:
        return Icons.error_outline;
    }
  }

  Color get _color {
    switch (status) {
      case NavStatus.idle:
        return AppTheme.textSecondary;
      case NavStatus.starting:
        return AppTheme.primary;
      case NavStatus.running:
        return AppTheme.success;
      case NavStatus.error:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true, // announces changes to screen readers automatically
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, color: _color),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: _color, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
