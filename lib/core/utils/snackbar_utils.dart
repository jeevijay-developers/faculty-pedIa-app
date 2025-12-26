import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    Color backgroundColor;
    IconData icon;
    
    switch (type) {
      case SnackBarType.success:
        backgroundColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case SnackBarType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case SnackBarType.warning:
        backgroundColor = AppColors.warning;
        icon = Icons.warning_amber_outlined;
        break;
      case SnackBarType.info:
        backgroundColor = AppColors.info;
        icon = Icons.info_outline;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }
  
  static void success(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.success);
  }
  
  static void error(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.error);
  }
  
  static void warning(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.warning);
  }
  
  static void info(BuildContext context, String message) {
    show(context, message: message, type: SnackBarType.info);
  }
}

enum SnackBarType { success, error, warning, info }
