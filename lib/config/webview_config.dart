class WebViewConfig {
  // Konfigurasi URL untuk WebView
  
  // Development URL - Next.js running locally
  // Pilih salah satu sesuai dengan device Anda:
  
  // UNTUK ANDROID EMULATOR (AKTIF SEKARANG):
  static const String developmentUrl = 'http://10.0.2.2:3000';
  
  // UNTUK PHYSICAL DEVICE - uncomment line di bawah jika pakai HP fisik:
  // static const String developmentUrl = 'http://192.168.1.8:3000';
  
  // UNTUK iOS SIMULATOR - uncomment line di bawah:
  // static const String developmentUrl = 'http://localhost:3000';
  
  // Production URL - Next.js deployed
  static const String productionUrl = 'https://your-nextjs-app.vercel.app';
  
  // Current active URL
  static const bool isDevelopment = true;
  static String get baseUrl => isDevelopment ? developmentUrl : productionUrl;
  
  // WebView Settings
  static const bool enableJavaScript = true;
  static const bool enableDomStorage = true;
  static const bool enableDebugging = true;
  
  // App Configuration
  static const String appTitle = 'Tracer Study ITK';
  static const bool showNavigationControls = true;
  static const bool showFloatingHomeButton = true;
}
