import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NoInternetDialog {
  static bool _isShowing = false;

  static Future<void> show() async {
    if (_isShowing) {
      return;
    }
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }
    _isShowing = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content: const Text(
              'Please check your internet connection and try again.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Retry'),
              ),
            ],
          );
        },
      );
    } finally {
      _isShowing = false;
    }
  }
}
