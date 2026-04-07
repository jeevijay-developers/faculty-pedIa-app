import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/widgets/state_widgets.dart';
import '../auth/providers/auth_provider.dart';

class StudentCourseItem {
  final String id;
  final String title;
  final String status;
  final double progress;
  final DateTime? enrolledAt;
  final String? imageUrl;
  final String? instructor;

  const StudentCourseItem({
    required this.id,
    required this.title,
    required this.status,
    required this.progress,
    this.enrolledAt,
    this.imageUrl,
    this.instructor,
  });
}

class StudentCoursesData {
  final List<StudentCourseItem> courses;
  final int totalEnrolled;
  final int ongoing;
  final int completed;
  final int upcoming;

  const StudentCoursesData({
    required this.courses,
    required this.totalEnrolled,
    required this.ongoing,
    required this.completed,
    required this.upcoming,
  });
}

final studentCoursesProvider =
    FutureProvider.autoDispose<StudentCoursesData>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final response = await api.get('/api/students/$studentId');
  final payload = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};
  final data = payload['data'] is Map<String, dynamic>
      ? payload['data'] as Map<String, dynamic>
      : payload;

  final rawCourses = data['courses'];
  final courses = <StudentCourseItem>[];

  if (rawCourses is List) {
    for (final entry in rawCourses) {
      if (entry is! Map<String, dynamic>) continue;
      final courseData = entry['courseId'] is Map<String, dynamic>
          ? entry['courseId'] as Map<String, dynamic>
          : <String, dynamic>{};
      final courseId =
          courseData['_id']?.toString() ?? entry['courseId']?.toString() ?? '';
      final title = courseData['title']?.toString() ?? 'Course';
      final status = entry['completionStatus']?.toString() ?? 'enrolled';
      final progress = (entry['progressPercentage'] as num?)?.toDouble() ?? 0;
      final enrolledAtRaw = entry['enrolledAt']?.toString();
      final enrolledAt =
          enrolledAtRaw != null ? DateTime.tryParse(enrolledAtRaw) : null;
      final imageUrl = _resolveCourseImage(courseData);
      final instructor = _resolveInstructor(courseData);

      courses.add(
        StudentCourseItem(
          id: courseId,
          title: title,
          status: status,
          progress: progress,
          enrolledAt: enrolledAt,
          imageUrl: imageUrl,
          instructor: instructor,
        ),
      );
    }
  }

  final totalEnrolled = courses.length;
  final ongoing = courses.where((course) => _isOngoing(course.status)).length;
  final completed =
      courses.where((course) => course.status == 'completed').length;
  final upcoming =
      courses.where((course) => course.status == 'upcoming').length;

  return StudentCoursesData(
    courses: courses,
    totalEnrolled: totalEnrolled,
    ongoing: ongoing,
    completed: completed,
    upcoming: upcoming,
  );
});

final courseFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');
final courseSearchProvider = StateProvider.autoDispose<String>((ref) => '');

String? _resolveCourseImage(Map<String, dynamic> courseData) {
  final image = courseData['image'];
  if (image is String && image.isNotEmpty) return image;
  if (image is Map<String, dynamic>) {
    return image['url']?.toString() ?? image['secure_url']?.toString();
  }
  final thumbnail = courseData['courseThumbnail'];
  if (thumbnail is String && thumbnail.isNotEmpty) return thumbnail;
  if (thumbnail is Map<String, dynamic>) {
    return thumbnail['url']?.toString() ?? thumbnail['secure_url']?.toString();
  }
  return null;
}

String? _resolveInstructor(Map<String, dynamic> courseData) {
  final educator = courseData['educatorID'] ?? courseData['educatorId'];
  if (educator is String) return null;
  if (educator is Map<String, dynamic>) {
    return educator['fullName']?.toString() ?? educator['name']?.toString();
  }
  return null;
}

bool _isOngoing(String status) {
  return status == 'enrolled' || status == 'in-progress' || status == 'started';
}

class StudentCoursesScreen extends ConsumerWidget {
  const StudentCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(studentCoursesProvider);
    final filter = ref.watch(courseFilterProvider);
    final searchQuery = ref.watch(courseSearchProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.grey900),
        title: const Text(
          'Academic Atelier',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const HamburgerDrawer(),
      body: Container(
        color: const Color(0xFFF6F4FF),
        child: coursesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(studentCoursesProvider),
          ),
          data: (coursesData) {
            final filteredCourses = _applyFilters(
              coursesData.courses,
              filter,
              searchQuery,
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentCoursesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Learning Journey',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSearchField(
                      onChanged: (value) =>
                          ref.read(courseSearchProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.school_outlined,
                            label: 'TOTAL ENROLLED',
                            value: coursesData.totalEnrolled.toString(),
                            color: const Color(0xFFEFF2FF),
                            iconColor: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.play_circle_outline,
                            label: 'ONGOING',
                            value: coursesData.ongoing.toString(),
                            color: const Color(0xFFE5F4FF),
                            iconColor: const Color(0xFF4B8CFF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.check_circle_outline,
                            label: 'COMPLETED',
                            value: coursesData.completed.toString(),
                            color: const Color(0xFFEFFAF2),
                            iconColor: const Color(0xFF2DBE6C),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.update,
                            label: 'UPCOMING',
                            value: coursesData.upcoming.toString(),
                            color: const Color(0xFFFFF3EA),
                            iconColor: const Color(0xFFFF7A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: 'All Courses',
                          isSelected: filter == 'all',
                          onSelected: () => ref
                              .read(courseFilterProvider.notifier)
                              .state = 'all',
                        ),
                        _buildFilterChip(
                          label: 'Ongoing',
                          isSelected: filter == 'ongoing',
                          onSelected: () => ref
                              .read(courseFilterProvider.notifier)
                              .state = 'ongoing',
                        ),
                        _buildFilterChip(
                          label: 'Upcoming',
                          isSelected: filter == 'upcoming',
                          onSelected: () => ref
                              .read(courseFilterProvider.notifier)
                              .state = 'upcoming',
                        ),
                        _buildFilterChip(
                          label: 'Completed',
                          isSelected: filter == 'completed',
                          onSelected: () => ref
                              .read(courseFilterProvider.notifier)
                              .state = 'completed',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (filteredCourses.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.menu_book_outlined,
                        title: 'No Courses Found',
                        subtitle: 'Try a different filter or search term',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredCourses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) =>
                            _buildCourseCard(context, filteredCourses[index]),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField({required ValueChanged<String> onChanged}) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search your courses...',
        prefixIcon: const Icon(Icons.search, color: AppColors.grey500),
        filled: true,
        fillColor: const Color(0xFFEDEBFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFDCD8FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, StudentCourseItem course) {
    final statusLabel = course.status.replaceAll('-', ' ').toUpperCase();
    final statusColor = _statusColor(course.status);
    final progressValue = (course.progress / 100).clamp(0, 1).toDouble();
    final enrolledDate = course.enrolledAt != null
        ? '${course.enrolledAt!.day}/${course.enrolledAt!.month}/${course.enrolledAt!.year}'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.grey900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          course.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.instructor ?? 'Instructor',
                      style: const TextStyle(
                          color: AppColors.grey600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (enrolledDate != null)
                Text(
                  enrolledDate,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.ondemand_video,
                  size: 16, color: AppColors.grey600),
              const SizedBox(width: 6),
              const Text('0 Videos',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600)),
              const SizedBox(width: 16),
              const Icon(Icons.description_outlined,
                  size: 16, color: AppColors.grey600),
              const SizedBox(width: 6),
              const Text('0 Tests',
                  style: TextStyle(fontSize: 12, color: AppColors.grey600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Progress ${course.progress.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 12, color: AppColors.grey600),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE7ECFF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(
                '/course-panel/${course.id}',
                extra: {
                  'title': course.title,
                  'imageUrl': course.imageUrl,
                },
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Continue Learning'),
            ),
          ),
        ],
      ),
    );
  }

  List<StudentCourseItem> _applyFilters(
    List<StudentCourseItem> courses,
    String filter,
    String searchQuery,
  ) {
    final query = searchQuery.trim().toLowerCase();
    return courses.where((course) {
      final matchesSearch =
          query.isEmpty || course.title.toLowerCase().contains(query);
      if (!matchesSearch) return false;

      switch (filter) {
        case 'ongoing':
          return _isOngoing(course.status);
        case 'completed':
          return course.status == 'completed';
        case 'upcoming':
          return course.status == 'upcoming';
        default:
          return true;
      }
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF2DBE6C);
      case 'upcoming':
        return const Color(0xFFFF7A1A);
      case 'in-progress':
      case 'enrolled':
      case 'started':
        return AppColors.primary;
      default:
        return AppColors.grey600;
    }
  }
}
