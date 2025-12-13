import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart';
import '../pages/home_page.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Memulai aplikasi...';
  
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Configure backend
    String? backendUrl;
    
    try {
      setState(() {
        _statusMessage = ApiConfig.isProduction 
            ? 'Menghubungkan ke server...'
            : 'Mencari server...';
      });
      
      backendUrl = await ApiConfig.getBaseUrl().timeout(
        Duration(seconds: ApiConfig.isProduction ? 10 : 20),
        onTimeout: () {
          debugPrint('⏱️ Timeout connecting to backend');
          return ApiConfig.developmentFallback;
        },
      );
      
      debugPrint('✅ Backend configured: $backendUrl');
      setState(() {
        _statusMessage = 'Terhubung!';
      });
    } catch (e) {
      debugPrint('⚠️ Backend setup: $e');
      backendUrl = ApiConfig.isProduction 
          ? ApiConfig.productionUrl 
          : ApiConfig.developmentFallback;
      setState(() {
        _statusMessage = 'Menggunakan konfigurasi default';
      });
    }

    // Minimal delay for splash visibility
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Check if user is already logged in
    if (AuthService.isLoggedIn && AuthService.currentUser != null) {
      // User is logged in, navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            employee: AuthService.currentUserMap ?? {},
          ),
        ),
      );
    } else {
      // User is not logged in, navigate to login page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 200,
              height: 200,
              child: Image.asset(
                'assets/images/Logo ITK.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school,
                    size: 120,
                    color: Colors.blue[700],
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            // App name
            const Text(
              'Tracer Study ITK',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0066CC),
              ),
            ),
            const SizedBox(height: 16),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066CC)),
            ),
            const SizedBox(height: 20),
            // Status message
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
