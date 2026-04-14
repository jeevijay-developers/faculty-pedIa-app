import 'package:connectivity_plus/connectivity_plus.dart';

class InternetService {
  static final InternetService _instance = InternetService._internal();
  factory InternetService() => _instance;

  final Connectivity _connectivity = Connectivity();

  InternetService._internal();

  Future<bool> hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<bool> hasInternetConnection() {
    return InternetService().hasInternet();
  }
}
