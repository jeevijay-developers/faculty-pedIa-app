import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final response = await api.get('/api/notifications/$studentId');
  final payload = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};

  final data = payload['data'] is Map<String, dynamic>
      ? payload['data'] as Map<String, dynamic>
      : payload;

  final rawNotifications = data['notifications'] ?? data['data'] ?? data;

  if (rawNotifications is! List) return const [];

  return rawNotifications
      .whereType<Map<String, dynamic>>()
      .map(AppNotification.fromJson)
      .toList();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final response = await api.get('/api/notifications/$studentId/unread-count');
  final payload = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};

  final data = payload['data'] is Map<String, dynamic>
      ? payload['data'] as Map<String, dynamic>
      : payload;

  return (data['unreadCount'] as num?)?.toInt() ?? 0;
});
