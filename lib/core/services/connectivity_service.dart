import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  
  ConnectivityService._internal() {
    _initConnectivity();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }
  
  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  
  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _isConnected = false;
      _connectionStatusController.add(false);
    }
  }
  
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final hasConnection = results.isNotEmpty && 
        results.any((result) => result != ConnectivityResult.none);
    _isConnected = hasConnection;
    _connectionStatusController.add(hasConnection);
  }
  
  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty && 
        result.any((result) => result != ConnectivityResult.none);
  }
  
  void dispose() {
    _connectionStatusController.close();
  }
}
