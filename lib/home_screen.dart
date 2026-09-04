import 'package:flutter/material.dart';
//import 'navigation_screen.dart';
import 'theme/app_theme.dart';
import 'screens/camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              Semantics(
                header: true,
                child: Text(
                  'VisionGuide',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Point your phone forward and start. '
                'You will hear obstacles announced as you walk — '
                'what they are, how far, and which way to move.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const Spacer(flex: 3),

              Semantics(
                button: true,
                label: 'Start navigation, begins live obstacle detection',
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CameraScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start Navigation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Semantics(
                button: true,
                label: 'Open settings',
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Settings screen — coming in a later phase',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    side: const BorderSide(
                      color: AppTheme.textSecondary,
                    ),
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}