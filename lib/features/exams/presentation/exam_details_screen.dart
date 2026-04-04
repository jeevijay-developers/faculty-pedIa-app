import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';

// Exam courses provider
final examCoursesProvider = FutureProvider.family
    .autoDispose<List<Course>, String>((ref, examType) async {
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
  final response = await api.get('/api/courses/specialization/$specialization');
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
  final String? initialCourseType;

  const ExamDetailsScreen({
    super.key,
    required this.examType,
    this.initialCourseType,
  });

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
            _CoursesTab(
              examType: examType,
              initialCourseType: initialCourseType,
            ),
            _TestSeriesTab(examType: examType),
            _EducatorsTab(examType: examType),
          ],
        ),
      ),
    );
  }
}

class _CoursesTab extends ConsumerStatefulWidget {
  final String examType;
  final String? initialCourseType;

  const _CoursesTab({
    required this.examType,
    this.initialCourseType,
  });

  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  String _selectedType = 'one-to-all';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCourseType;
    if (initial == 'one-to-all' || initial == 'one-to-one') {
      _selectedType = initial!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(examCoursesProvider(widget.examType));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(examCoursesProvider(widget.examType));
      },
      child: coursesAsync.when(
        loading: () => const ShimmerList(itemCount: 5),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(examCoursesProvider(widget.examType)),
        ),
        data: (courses) {
          final filteredCourses = courses
              .where((course) => course.courseType == _selectedType)
              .toList();
          if (courses.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.play_circle_outline,
              title: 'No Courses Available',
              subtitle: 'Check back later for new courses',
            );
          }
          if (filteredCourses.isEmpty) {
            return Column(
              children: [
                _buildTypeTabs(),
                const Expanded(
                  child: Center(
                    child: Text('No courses found for this type.'),
                  ),
                ),
              ],
            );
          }

          return Column(
            children: [
              _buildTypeTabs(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = filteredCourses[index];
                    return _CourseListItem(course: course);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TypeTabButton(
                label: 'One to All',
                isSelected: _selectedType == 'one-to-all',
                onTap: () => setState(() {
                  _selectedType = 'one-to-all';
                }),
              ),
            ),
            Expanded(
              child: _TypeTabButton(
                label: 'One to One',
                isSelected: _selectedType == 'one-to-one',
                onTap: () => setState(() {
                  _selectedType = 'one-to-one';
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.grey600,
            ),
          ),
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
