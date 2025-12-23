import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/webview_config.dart';
// import '../services/auth_service.dart';

/// WebView Page dengan Authentication Integration
/// Versi ini akan mengirim token ke web app untuk auto-login
class WebViewAuthPage extends StatefulWidget {
  const WebViewAuthPage({super.key});

  @override
  State<WebViewAuthPage> createState() => _WebViewAuthPageState();
}

class _WebViewAuthPageState extends State<WebViewAuthPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _authToken;

  static String get _initialUrl => WebViewConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadAuthAndInitialize();
  }

  Future<void> _loadAuthAndInitialize() async {
    // Load auth token dari AuthService
    // _authToken = await AuthService.getToken();
    _initializeWebView();
  }

  void _initializeWebView() async {
    final WebViewController controller = WebViewController();

    // Clear cache untuk memastikan load JavaScript terbaru
    await controller.clearCache();
    await controller.clearLocalStorage();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      // Custom User Agent tanpa 'FlutterWebView' agar frontend detect sebagai browser biasa
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (progress == 100) {
              setState(() {
                _isLoading = false;
              });
              // Inject auth token setelah page loaded
              _injectAuthToken();
            }
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Inject auth token setelah page loaded
            _injectAuthToken();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterAuth',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAuthMessage(message.message);
        },
      )
      // FlutterApp channel dihapus sementara untuk menghindari detection
      // yang menyebabkan frontend menggunakan URL localhost
      ..loadRequest(Uri.parse(_initialUrl));

    _controller = controller;
  }

  /// Inject auth token ke web app via localStorage
  Future<void> _injectAuthToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      final script =
          '''
        localStorage.setItem('auth_token', '$_authToken');
        // Trigger custom event untuk notify web app
        window.dispatchEvent(new Event('flutter_auth_ready'));
      ''';
      await _controller.runJavaScript(script);
      debugPrint('Auth token injected to WebView');
    }
  }

  /// Handle pesan authentication dari web app
  void _handleAuthMessage(String message) {
    debugPrint('Auth message: $message');

    // Parse message sebagai JSON jika perlu
    // Example: {"action": "logout"}
    if (message == 'logout') {
      _handleLogout();
    }
  }

  /// Handle pesan umum dari web app
  void _handleAppMessage(String message) {
    debugPrint('App message: $message');

    // Handle berbagai aksi dari web app
    switch (message) {
      case 'openNativeDashboard':
        Navigator.pushNamed(context, '/dashboard');
        break;
      case 'openNativeProfile':
        Navigator.pushNamed(context, '/profile');
        break;
      default:
        debugPrint('Unknown message: $message');
    }
  }

  /// Handle logout dari web app
  Future<void> _handleLogout() async {
    // Clear auth di Flutter
    // await AuthService.logout();

    // Clear localStorage di WebView
    await _controller.runJavaScript('localStorage.clear();');

    // Navigate ke login page
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _refreshPage() async {
    await _controller.reload();
  }

  Future<bool> _handleBackButton() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        appBar: WebViewConfig.showNavigationControls
            ? AppBar(
                title: Text(WebViewConfig.appTitle),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshPage,
                    tooltip: 'Refresh',
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () async {
                      if (await _controller.canGoForward()) {
                        await _controller.goForward();
                      }
                    },
                    tooltip: 'Forward',
                  ),
                  // Optional: Logout button
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _handleLogout,
                    tooltip: 'Logout',
                  ),
                ],
              )
            : null,
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: WebViewConfig.showFloatingHomeButton
            ? FloatingActionButton(
                onPressed: () {
                  _controller.loadRequest(Uri.parse(_initialUrl));
                },
                tooltip: 'Home',
                child: const Icon(Icons.home),
              )
            : null,
      ),
    );
  }
}
