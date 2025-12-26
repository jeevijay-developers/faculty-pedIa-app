import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';

// Exam courses provider
final examCoursesProvider = FutureProvider.family.autoDispose<List<Course>, String>((ref, examType) async {
  final api = ApiService();
  final response = await api.get('/api/courses/specialization/$examType');
  final data = response.data;
  
  List<dynamic> coursesList = [];
  if (data is Map && data['courses'] != null) {
    coursesList = data['courses'] as List;
  } else if (data is List) {
    coursesList = data;
  }
  
  return coursesList.map((e) => Course.fromJson(e)).toList();
});

class ExamDetailsScreen extends ConsumerWidget {
  final String examType;
  
  const ExamDetailsScreen({super.key, required this.examType});

  String get examName {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('$examName Preparation'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Courses'),
              Tab(text: 'Test Series'),
              Tab(text: 'Educators'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CoursesTab(examType: examType),
            _TestSeriesTab(examType: examType),
            _EducatorsTab(examType: examType),
          ],
        ),
      ),
    );
  }
}

class _CoursesTab extends ConsumerWidget {
  final String examType;
  
  const _CoursesTab({required this.examType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(examCoursesProvider(examType));
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(examCoursesProvider(examType));
      },
      child: coursesAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(examCoursesProvider(examType)),
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
    );
  }
}

class _CourseListItem extends StatelessWidget {
  final Course course;
  
  const _CourseListItem({required this.course});

  @override
  Widget build(BuildContext context) {
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
                  child: const Icon(Icons.play_circle, color: AppColors.grey400),
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
                    Row(
                      children: [
                        Text(
                          '₹${course.finalPrice.toInt()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (course.hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${course.fees?.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
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
}

class _TestSeriesTab extends StatelessWidget {
  final String examType;
  
  const _TestSeriesTab({required this.examType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Test Series Coming Soon',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Practice tests for $examType will be available soon',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EducatorsTab extends StatelessWidget {
  final String examType;
  
  const _EducatorsTab({required this.examType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'Educators',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.go('/educators'),
            child: const Text('Browse All Educators'),
          ),
        ],
      ),
    );
  }
}
