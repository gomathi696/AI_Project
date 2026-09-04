import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'home_screen.dart';

void main() {
  runApp(const VisionGuideApp());
}

class VisionGuideApp extends StatelessWidget {
  const VisionGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}