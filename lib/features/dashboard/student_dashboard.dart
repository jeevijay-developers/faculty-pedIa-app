import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/widgets/state_widgets.dart';
import '../auth/providers/auth_provider.dart';

class StudentDashboardStats {
  final int totalCourses;
  final int testsTaken;
  final int totalEducatorsFollowing;

  const StudentDashboardStats({
    required this.totalCourses,
    required this.testsTaken,
    required this.totalEducatorsFollowing,
  });
}

class DashboardTestResult {
  final String title;
  final double percentage;
  final DateTime? completedAt;

  const DashboardTestResult({
    required this.title,
    required this.percentage,
    this.completedAt,
  });
}

class StudentDashboardData {
  final StudentDashboardStats stats;
  final List<DashboardTestResult> recentResults;

  const StudentDashboardData({
    required this.stats,
    required this.recentResults,
  });
}

final studentDashboardProvider =
    FutureProvider.autoDispose<StudentDashboardData>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final responses = await Future.wait([
    api.get('/api/students/$studentId/statistics'),
    api.get('/api/students/$studentId'),
  ]);

  final statsPayload = responses[0].data is Map<String, dynamic>
      ? responses[0].data as Map<String, dynamic>
      : <String, dynamic>{};
  final statsData = statsPayload['data'] is Map<String, dynamic>
      ? statsPayload['data'] as Map<String, dynamic>
      : statsPayload;

  final stats = StudentDashboardStats(
    totalCourses: (statsData['totalCourses'] as num?)?.toInt() ?? 0,
    testsTaken: (statsData['testsTaken'] as num?)?.toInt() ?? 0,
    totalEducatorsFollowing:
        (statsData['totalEducatorsFollowing'] as num?)?.toInt() ?? 0,
  );

  final detailsPayload = responses[1].data is Map<String, dynamic>
      ? responses[1].data as Map<String, dynamic>
      : <String, dynamic>{};
  final detailsData = detailsPayload['data'] is Map<String, dynamic>
      ? detailsPayload['data'] as Map<String, dynamic>
      : detailsPayload;

  final results = _parseRecentResults(detailsData['results']);

  return StudentDashboardData(stats: stats, recentResults: results);
});

List<DashboardTestResult> _parseRecentResults(dynamic rawResults) {
  if (rawResults is! List) return const [];

  final parsed = rawResults.whereType<Map<String, dynamic>>().map((result) {
    final percentage = (result['percentage'] as num?)?.toDouble() ?? 0;
    final title = result['testTitle']?.toString() ?? 'Test Result';
    final completedAtRaw = result['completedAt'] ?? result['submittedAt'];
    final completedAt =
        completedAtRaw is String ? DateTime.tryParse(completedAtRaw) : null;
    return DashboardTestResult(
      title: title,
      percentage: percentage,
      completedAt: completedAt,
    );
  }).toList();

  parsed.sort((a, b) {
    final aTime = a.completedAt?.millisecondsSinceEpoch ?? 0;
    final bTime = b.completedAt?.millisecondsSinceEpoch ?? 0;
    return bTime.compareTo(aTime);
  });

  return parsed.take(3).toList();
}

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final displayName = user?.displayName ?? 'Student';
    final dashboardAsync = ref.watch(studentDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.grey900),
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.grey200,
              backgroundImage: (user?.imageUrl ?? '').isNotEmpty
                  ? NetworkImage(user!.imageUrl!)
                  : null,
              child: (user?.imageUrl ?? '').isEmpty
                  ? const Icon(Icons.person, size: 18, color: AppColors.grey700)
                  : null,
            ),
            const SizedBox(width: 12),
            const Text(
              'Academic Atelier',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
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
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(studentDashboardProvider),
          ),
          data: (dashboard) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentDashboardProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DASHBOARD',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome back, $displayName 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildEnrolledCard(
                        totalCourses: dashboard.stats.totalCourses),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.assignment_outlined,
                            title: 'Tests Taken',
                            value: dashboard.stats.testsTaken.toString(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.people_outline,
                            title: 'Following',
                            value: dashboard.stats.totalEducatorsFollowing
                                .toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(
                      title: 'Upcoming Live Class',
                      actionLabel: 'Go to Live Classes',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildUpcomingClassCard(),
                    const SizedBox(height: 20),
                    const Text(
                      'Recent Tests',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentTestsCard(dashboard.recentResults),
                    const SizedBox(height: 12),
                    _buildStudyTipCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEnrolledCard({required int totalCourses}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enrolled Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Active learning journey',
                  style: TextStyle(color: AppColors.grey600, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                totalCourses.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
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
            title,
            style: const TextStyle(color: AppColors.grey600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.grey900,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingClassCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDC7FF)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_busy, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            'No classes scheduled',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your upcoming live sessions will appear here once they are set.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTestsCard(List<DashboardTestResult> results) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF2FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.edit_note, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'No tests enrolled yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Start your academic progress by enrolling in your first assessment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey700, fontSize: 12),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Explore Tests'),
            ),
          ],
        ),
      );
    }

    final latest = results.first;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.edit_note, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            latest.title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Latest score: ${latest.percentage.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Results'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D1333), Color(0xFF142052)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STUDY TIP',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The 50/10 Pomodoro technique boosts retention.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.timer_outlined, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
