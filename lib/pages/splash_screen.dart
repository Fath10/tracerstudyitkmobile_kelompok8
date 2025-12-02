import 'package:flutter/material.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // User already loaded in main.dart, just check status
    // Minimal delay for splash visibility (reduced from 2s to 1s)
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
            const SizedBox(height: 80),
            // Version or tagline
            Text(
              'Loading...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
