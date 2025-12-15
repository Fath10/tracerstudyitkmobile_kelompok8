import 'package:flutter/material.dart';

import '../config/webview_config.dart';
import '../pages/webview_page.dart';

/// Splash screen yang langsung redirect ke WebView
/// Gunakan ini jika Anda ingin langsung load WebView saat app start
class WebViewSplashScreen extends StatefulWidget {
  const WebViewSplashScreen({super.key});

  @override
  State<WebViewSplashScreen> createState() => _WebViewSplashScreenState();
}

class _WebViewSplashScreenState extends State<WebViewSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Tunggu sebentar untuk splash effect
    await Future.delayed(const Duration(seconds: 2));
    
    // Optional: Load user session jika diperlukan
    // await AuthService.loadUser();
    
    // Navigate ke WebView
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebViewPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo atau Icon
              Icon(
                Icons.school,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              // Nama App
              Text(
                WebViewConfig.appTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 16),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
