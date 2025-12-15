import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'pages/webview_page.dart';

/// SIMPLE VERSION - App langsung load WebView
/// Copy file ini menjadi main.dart jika Anda ingin app HANYA menampilkan WebView
/// 
/// Steps:
/// 1. Backup main.dart lama: mv lib/main.dart lib/main_backup.dart
/// 2. Copy file ini: cp lib/main_webview_only.dart lib/main.dart
/// 3. Run: flutter run

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tracer Study ITK',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WebViewPage(),
    );
  }
}
