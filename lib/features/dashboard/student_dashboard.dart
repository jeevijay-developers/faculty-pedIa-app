import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../loading/skeleton.dashboard.dart';
import '../auth/providers/auth_provider.dart';

// ── Design tokens (monochromatic Blue-600) ─────────────────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

const kSurface = Colors.white;
const kSurfaceDark = Color(0xFF1E293B);
const kBgLight = Color(0xFFF8FAFC);
const kBgDark = Color(0xFF0F172A);
const kText1Light = Color(0xFF0F172A);
const kText2Light = Color(0xFF64748B);
const kText3Light = Color(0xFF94A3B8);
const kText1Dark = Colors.white;
const kText2Dark = Color(0xFF94A3B8);
const kDivLight = Color(0xFFF1F5F9);

// ── Models ─────────────────────────────────────────────────────────────────────
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

// ── Provider ───────────────────────────────────────────────────────────────────
final studentDashboardProvider =
    FutureProvider.autoDispose<StudentDashboardData>((ref) async {
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final responses = await Future.wait([
    api.get('/api/students/$studentId/statistics'),
    api.get('/api/students/$studentId'),
  ]);

  final sp = responses[0].data is Map<String, dynamic>
      ? responses[0].data as Map<String, dynamic>
      : <String, dynamic>{};
  final sd = sp['data'] is Map<String, dynamic>
      ? sp['data'] as Map<String, dynamic>
      : sp;

  final stats = StudentDashboardStats(
    totalCourses: (sd['totalCourses'] as num?)?.toInt() ?? 0,
    testsTaken: (sd['testsTaken'] as num?)?.toInt() ?? 0,
    totalEducatorsFollowing:
        (sd['totalEducatorsFollowing'] as num?)?.toInt() ?? 0,
  );

  final dp = responses[1].data is Map<String, dynamic>
      ? responses[1].data as Map<String, dynamic>
      : <String, dynamic>{};
  final dd = dp['data'] is Map<String, dynamic>
      ? dp['data'] as Map<String, dynamic>
      : dp;

  return StudentDashboardData(
      stats: stats, recentResults: _parseResults(dd['results']));
});

List<DashboardTestResult> _parseResults(dynamic raw) {
  if (raw is! List) return const [];
  final parsed = raw.whereType<Map<String, dynamic>>().map((r) {
    final dt = r['completedAt'] ?? r['submittedAt'];
    return DashboardTestResult(
      title: r['testTitle']?.toString() ?? 'Test Result',
      percentage: (r['percentage'] as num?)?.toDouble() ?? 0,
      completedAt: dt is String ? DateTime.tryParse(dt) : null,
    );
  }).toList()
    ..sort((a, b) => (b.completedAt?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.completedAt?.millisecondsSinceEpoch ?? 0));
  return parsed.take(3).toList();
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = auth.user?.displayName?.split(' ').first ?? 'Student';
    final dashboardAsync = ref.watch(studentDashboardProvider);
    final unreadCount = 0; // wire to your unread provider if needed

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: dashboardAsync.when(
        loading: () => const StudentDashboardSkeleton(),
        error: (e, _) => ErrorStateWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(studentDashboardProvider),
        ),
        data: (dashboard) => RefreshIndicator(
          color: kPrimary,
          onRefresh: () async => ref.invalidate(studentDashboardProvider),
          child: CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────────────────
              _buildSliverAppBar(context, auth, isDark, displayName),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats row ──────────────────────────────────
                      _buildStatsRow(dashboard.stats, isDark),

                      const SizedBox(height: 24),

                      // ── Enrolled courses card ──────────────────────
                      _sectionLabel('My Learning', isDark),
                      const SizedBox(height: 12),
                      _buildEnrolledCard(
                          dashboard.stats.totalCourses, isDark, context),

                      const SizedBox(height: 24),

                      // ── Upcoming live class ────────────────────────
                      _buildSectionHeader(
                        'Upcoming Live Class',
                        'Go to Live Classes',
                        isDark,
                        onTap: () => context.push('/live'),
                      ),
                      const SizedBox(height: 12),
                      _buildUpcomingCard(isDark),

                      const SizedBox(height: 24),

                      // ── Recent tests ───────────────────────────────
                      _buildSectionHeader(
                        'Recent Tests',
                        'View All',
                        isDark,
                        onTap: () => context.push('/test-series'),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentTests(
                          dashboard.recentResults, isDark, context),

                      const SizedBox(height: 24),

                      // ── Study tip ──────────────────────────────────
                      _buildStudyTip(isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    AuthState auth,
    bool isDark,
    String displayName,
  ) {
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_outlined,
                color: Colors.white, size: 19),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MY DASHBOARD',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Hello, $displayName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your learning progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
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

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow(StudentDashboardStats stats, bool isDark) {
    final items = [
      _StatItem(Icons.menu_book_rounded, '${stats.totalCourses}', 'Courses'),
      _StatItem(Icons.assignment_rounded, '${stats.testsTaken}', 'Tests'),
      _StatItem(Icons.people_rounded, '${stats.totalEducatorsFollowing}',
          'Following'),
    ];

    return Row(
      children: items.map((s) {
        final isLast = s == items.last;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _StatCard(stat: s, isDark: isDark)),
              if (!isLast) const SizedBox(width: 10),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Enrolled courses card ─────────────────────────────────────────────────
  Widget _buildEnrolledCard(int count, bool isDark, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/courses'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: kPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enrolled Courses',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? kText1Dark : kText1Light,
                      )),
                  const SizedBox(height: 3),
                  Text('Active learning journey',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? kText2Dark : kText2Light,
                      )),
                ],
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming class card ───────────────────────────────────────────────────
  Widget _buildUpcomingCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_available_rounded,
                color: kPrimary, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            'No classes scheduled',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your upcoming live sessions will appear here once they are set.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent tests ──────────────────────────────────────────────────────────
  Widget _buildRecentTests(
    List<DashboardTestResult> results,
    bool isDark,
    BuildContext context,
  ) {
    if (results.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: kPrimary, size: 26),
            ),
            const SizedBox(height: 14),
            Text('No tests taken yet',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const SizedBox(height: 6),
            Text(
              'Enroll in your first test series to start tracking progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? kText2Dark : kText2Light,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => context.push('/test-series'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Explore Tests',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: results
          .map((r) => _TestResultRow(result: r, isDark: isDark))
          .toList(),
    );
  }

  // ── Study tip card ────────────────────────────────────────────────────────
  Widget _buildStudyTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDY TIP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1.5,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'The 50/10 Pomodoro technique boosts retention by 40%.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.timer_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) => Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: isDark ? kText1Dark : kText1Light,
        ),
      );

  Widget _buildSectionHeader(
    String title,
    String actionLabel,
    bool isDark, {
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? kText1Dark : kText1Light,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? kSurfaceDark : kPrimaryBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : kPrimaryMid,
              ),
            ),
            child: const Text(
              'See All',
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String value, label;
  const _StatItem(this.icon, this.value, this.label);
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(stat.icon, color: kPrimary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? kText2Dark : kText3Light,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Test result row ────────────────────────────────────────────────────────────
class _TestResultRow extends StatelessWidget {
  final DashboardTestResult result;
  final bool isDark;
  const _TestResultRow({required this.result, required this.isDark});

  Color get _perfColor {
    if (result.percentage >= 85) return const Color(0xFF16A34A);
    if (result.percentage >= 70) return kPrimary;
    if (result.percentage >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String get _perfLabel {
    if (result.percentage >= 85) return 'Excellent';
    if (result.percentage >= 70) return 'Good';
    if (result.percentage >= 50) return 'Average';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child:
                const Icon(Icons.assignment_rounded, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isDark ? kText1Dark : kText1Light,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // mini progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: result.percentage / 100,
                    minHeight: 4,
                    backgroundColor:
                        isDark ? Colors.white.withOpacity(0.08) : kDivLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_perfColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: _perfColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _perfLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kText3Light,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
