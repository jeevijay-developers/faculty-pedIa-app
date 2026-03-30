class AppConfig {
  AppConfig._();

  static const String appName = 'Faculty Pedia';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Use 10.0.2.2 for Android emulator to reach your local machine.
  static const bool useLocalBackend = false;
  static const String baseUrl1 = 'https://facultypedia-server.onrender.com';
  static const String baseUrl =
      useLocalBackend ? 'http://10.0.2.2:5001' : baseUrl1;
  static const String apiPrefix = '/api';

  // Timeouts
  // Render free instances can cold-start; allow more time.
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Storage Keys
  static const String authTokenKey = 'faculty-pedia-auth-token';
  static const String userDataKey = 'faculty-pedia-user-data';
  static const String userRoleKey = 'user-role';
  static const String themeKey = 'theme-mode';
  static const String offlineResultsKey = 'faculty-pedia-offline-results';

  // Razorpay (placeholder - should be fetched from backend)
  static const String razorpayKeyId = '';

  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableDarkMode = true;
}
