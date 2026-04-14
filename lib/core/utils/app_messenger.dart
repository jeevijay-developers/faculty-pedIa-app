import 'package:flutter/material.dart';

import 'snackbar_utils.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppMessenger {
  static const String _networkErrorMessage = 'Network Connection Failed';
  static int _lastNetworkErrorMillis = 0;
  static const int _networkErrorMinIntervalMillis = 2000;

  static void showNetworkError() {
    final context = rootScaffoldMessengerKey.currentContext;
    if (context == null) {
      return;
    }
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    if (nowMillis - _lastNetworkErrorMillis < _networkErrorMinIntervalMillis) {
      return;
    }
    _lastNetworkErrorMillis = nowMillis;
    AppSnackbar.error(context, _networkErrorMessage);
  }
}
