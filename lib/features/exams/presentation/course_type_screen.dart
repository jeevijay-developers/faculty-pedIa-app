import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';

final courseTypeProvider = FutureProvider.family
    .autoDispose<List<Course>, ({String examType, String courseType})>(
        (ref, params) async {
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
  final specialization = specializationForApi(params.examType);
  final response = await api.get('/api/courses/specialization/$specialization');
  final data = response.data;

  List<dynamic> coursesList = [];
  if (data is Map && data['courses'] != null) {
    coursesList = data['courses'] as List;
  } else if (data is List) {
    coursesList = data;
  }

  final courses = coursesList.map((e) => Course.fromJson(e)).toList();
  return courses
      .where((course) => course.courseType == params.courseType)
      .toList();
});

class CourseTypeScreen extends ConsumerWidget {
  final String examType;
  final String courseType;

  const CourseTypeScreen({
    super.key,
    required this.examType,
    required this.courseType,
  });

  String get _title {
    if (courseType == 'one-to-one') return 'One to One Live Courses';
    return 'One to All Live Courses';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(
        courseTypeProvider((examType: examType, courseType: courseType)));

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
              courseTypeProvider((examType: examType, courseType: courseType)));
        },
        child: coursesAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(courseTypeProvider(
                (examType: examType, courseType: courseType))),
          ),
          data: (courses) {
            if (courses.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.play_circle_outline,
                title: 'No Courses Available',
                subtitle: 'Check back later for new courses',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _CourseListItem(course: course);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CourseListItem extends StatelessWidget {
  final Course course;

  const _CourseListItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(course.imageUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: AppColors.grey200,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.educator?.name ?? 'Educator',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${course.finalPrice.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Icon(Icons.play_circle, color: AppColors.grey400);
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
