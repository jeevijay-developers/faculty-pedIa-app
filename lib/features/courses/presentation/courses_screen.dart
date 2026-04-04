import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// Courses Provider
final coursesProvider = FutureProvider.autoDispose<List<Course>>((ref) async {
  final api = ApiService();
  final response = await api.get('/api/courses');
  final data = response.data;

  List<dynamic> coursesList = [];
  if (data is Map && data['courses'] != null) {
    coursesList = data['courses'] as List;
  } else if (data is List) {
    coursesList = data;
  }

  return coursesList.map((e) => Course.fromJson(e)).toList();
});

class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(coursesProvider);
        },
        child: coursesAsync.when(
          loading: () => const ShimmerList(itemCount: 5, itemHeight: 160),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(coursesProvider),
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
                return _CourseCard(course: courses[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl(course.imageUrl);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/course/${course.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
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

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Specialization badge
                  if (course.specialization.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: course.specialization.take(2).map((spec) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            spec,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Educator
                  if (course.educator != null)
                    Row(
                      children: [
                        UserAvatar(
                          imageUrl: course.educator!.profilePicture,
                          name: course.educator!.name,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.educator!.name ?? 'Educator',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),

                  // Price and action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriceWidget(
                        price: course.finalPrice,
                        originalPrice: course.fees,
                        discount: course.discount,
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/course/${course.id}'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text('View Details'),
                      ),
                    ],
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
        Icons.play_circle_outline,
        size: 48,
        color: AppColors.grey400,
      ),
    );
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
