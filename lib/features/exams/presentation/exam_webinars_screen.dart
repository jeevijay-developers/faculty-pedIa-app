import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/webinar_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

final examWebinarsProvider = FutureProvider.family
    .autoDispose<List<Webinar>, String>((ref, examType) async {
  String specializationForApi(String examType) {
    switch (examType.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      default:
        return examType.toUpperCase();
    }
  }

  final api = ApiService();
  final specialization = specializationForApi(examType);
  final response = await api.get(
    '/api/webinars',
    queryParameters: {'specialization': specialization},
  );
  final data = response.data;

  List<dynamic> webinarsList = [];
  if (data is Map && data['data'] != null && data['data']['webinars'] != null) {
    webinarsList = data['data']['webinars'] as List;
  } else if (data is Map && data['webinars'] != null) {
    webinarsList = data['webinars'] as List;
  } else if (data is List) {
    webinarsList = data;
  }

  return webinarsList.map((e) => Webinar.fromJson(e)).toList();
});

class ExamWebinarsScreen extends ConsumerWidget {
  final String examType;

  const ExamWebinarsScreen({super.key, required this.examType});

  String get _title {
    switch (examType.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE Webinars';
      case 'neet':
        return 'NEET Webinars';
      case 'cbse':
        return 'CBSE Webinars';
      default:
        return '${examType.toUpperCase()} Webinars';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webinarsAsync = ref.watch(examWebinarsProvider(examType));

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(examWebinarsProvider(examType));
        },
        child: webinarsAsync.when(
          loading: () => const ShimmerList(itemCount: 4, itemHeight: 180),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(examWebinarsProvider(examType)),
          ),
          data: (webinars) {
            if (webinars.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.videocam_outlined,
                title: 'No Webinars Available',
                subtitle: 'Check back later for upcoming webinars',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: webinars.length,
              itemBuilder: (context, index) {
                return _WebinarCard(webinar: webinars[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _WebinarCard extends StatelessWidget {
  final Webinar webinar;

  const _WebinarCard({required this.webinar});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(webinar.imageUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/webinar/${webinar.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.grey200,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: _buildStatusBadge(),
                ),
                if (webinar.isFree == true)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    webinar.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (webinar.educatorName != null)
                    Row(
                      children: [
                        UserAvatar(
                          imageUrl: webinar.educatorImage,
                          name: webinar.educatorName,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          webinar.educatorName!,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (webinar.scheduledAt != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: AppColors.grey600),
                        const SizedBox(width: 6),
                        Text(
                          DateFormatter.formatDateTime(webinar.scheduledAt!),
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 13,
                          ),
                        ),
                        if (webinar.duration != null) ...[
                          const SizedBox(width: 12),
                          Icon(Icons.timer, size: 14, color: AppColors.grey600),
                          const SizedBox(width: 4),
                          Text(
                            '${webinar.duration} min',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/webinar/${webinar.id}'),
                      child: Text(_getButtonText()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.videocam_outlined,
        size: 48,
        color: AppColors.grey400,
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    if (webinar.isLive) {
      color = AppColors.error;
      text = '● LIVE';
    } else if (webinar.isUpcoming) {
      color = AppColors.primary;
      text = 'UPCOMING';
    } else {
      color = AppColors.grey500;
      text = 'ENDED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getButtonText() {
    if (webinar.isLive) return 'Join Now';
    if (webinar.isUpcoming) return 'Register';
    return 'View Recording';
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    if (url.startsWith('/')) {
      return '${AppConfig.baseUrl}$url';
    }
    return '${AppConfig.baseUrl}/$url';
  }
}
