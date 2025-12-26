import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// Course Detail Provider
final courseDetailProvider = FutureProvider.family.autoDispose<Course, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/courses/$id');
  final data = response.data;
  
  Map<String, dynamic> courseData = {};
  if (data is Map && data['course'] != null) {
    courseData = data['course'];
  } else if (data is Map) {
    courseData = Map<String, dynamic>.from(data);
  }
  
  return Course.fromJson(courseData);
});

class CourseDetailsScreen extends ConsumerWidget {
  final String courseId;
  
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    
    return Scaffold(
      body: courseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Scaffold(
          appBar: AppBar(),
          body: ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
          ),
        ),
        data: (course) => _buildContent(context, course),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Course course) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.grey200,
              child: course.imageUrl.isNotEmpty
                  ? Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => context.pop(),
          ),
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specialization
                if (course.specialization.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: course.specialization.map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          spec,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  course.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                
                // Educator
                if (course.educator != null)
                  GestureDetector(
                    onTap: () => context.push('/educator/${course.educator!.id}'),
                    child: Row(
                      children: [
                        UserAvatar(
                          imageUrl: course.educator!.profilePicture,
                          name: course.educator!.name,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.educator!.name ?? 'Educator',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'View Profile',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Stats
                _buildStatsRow(course),
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'About this Course',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  course.description ?? 'No description available.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                
                // Subjects
                if (course.subject.isNotEmpty) ...[
                  Text(
                    'Subjects Covered',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: course.subject.map((subject) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Classes
                if (course.classes != null && course.classes!.isNotEmpty) ...[
                  Text(
                    'Course Schedule',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  ...course.classes!.map((cls) => _buildClassItem(context, cls)),
                ],
                
                const SizedBox(height: 100), // Space for bottom bar
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 64,
        color: AppColors.grey400,
      ),
    );
  }

  Widget _buildStatsRow(Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.calendar_today,
            'Starts',
            course.startDate != null
                ? DateFormatter.formatDate(course.startDate!)
                : 'TBA',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.people,
            'Max Students',
            '${course.maxStudents ?? 'Unlimited'}',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.person,
            'Enrolled',
            '${course.enrolledCount ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.grey300,
    );
  }

  Widget _buildClassItem(BuildContext context, CourseClass cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_arrow, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.title ?? 'Class',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (cls.scheduledAt != null)
                  Text(
                    DateFormatter.formatDateTime(cls.scheduledAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          if (cls.duration != null)
            Text(
              '${cls.duration} min',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
        ],
      ),
    );
  }
}
