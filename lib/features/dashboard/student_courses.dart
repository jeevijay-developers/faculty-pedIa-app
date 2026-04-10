import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/widgets/state_widgets.dart';
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
  final int totalEnrolled, ongoing, completed, upcoming;

  const StudentCoursesData({
    required this.courses,
    required this.totalEnrolled,
    required this.ongoing,
    required this.completed,
    required this.upcoming,
  });
}

// ── Providers ──────────────────────────────────────────────────────────────────
final studentCoursesProvider =
    FutureProvider.autoDispose<StudentCoursesData>((ref) async {
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
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
      final cd = entry['courseId'] is Map<String, dynamic>
          ? entry['courseId'] as Map<String, dynamic>
          : <String, dynamic>{};
      final courseId =
          cd['_id']?.toString() ?? entry['courseId']?.toString() ?? '';
      final enrolledAtRaw = entry['enrolledAt']?.toString();

      courses.add(StudentCourseItem(
        id: courseId,
        title: cd['title']?.toString() ?? 'Course',
        status: entry['completionStatus']?.toString() ?? 'enrolled',
        progress: (entry['progressPercentage'] as num?)?.toDouble() ?? 0,
        enrolledAt:
            enrolledAtRaw != null ? DateTime.tryParse(enrolledAtRaw) : null,
        imageUrl: _resolveCourseImage(cd),
        instructor: _resolveInstructor(cd),
      ));
    }
  }

  return StudentCoursesData(
    courses: courses,
    totalEnrolled: courses.length,
    ongoing: courses.where((c) => _isOngoing(c.status)).length,
    completed: courses.where((c) => c.status == 'completed').length,
    upcoming: courses.where((c) => c.status == 'upcoming').length,
  );
});

final courseFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');
final courseSearchProvider = StateProvider.autoDispose<String>((ref) => '');

// ── Helpers ────────────────────────────────────────────────────────────────────
String? _resolveCourseImage(Map<String, dynamic> cd) {
  for (final key in ['image', 'courseThumbnail']) {
    final v = cd[key];
    if (v is String && v.isNotEmpty) return v;
    if (v is Map<String, dynamic>) {
      return v['url']?.toString() ?? v['secure_url']?.toString();
    }
  }
  return null;
}

String? _resolveInstructor(Map<String, dynamic> cd) {
  final e = cd['educatorID'] ?? cd['educatorId'];
  if (e is Map<String, dynamic>) {
    return e['fullName']?.toString() ?? e['name']?.toString();
  }
  return null;
}

bool _isOngoing(String s) =>
    s == 'enrolled' || s == 'in-progress' || s == 'started';

// ── Screen ─────────────────────────────────────────────────────────────────────
class StudentCoursesScreen extends ConsumerStatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  ConsumerState<StudentCoursesScreen> createState() =>
      _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends ConsumerState<StudentCoursesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<StudentCourseItem> _applyFilters(
    List<StudentCourseItem> courses,
    String filter,
    String q,
  ) {
    return courses.where((c) {
      final matchSearch =
          q.isEmpty || c.title.toLowerCase().contains(q.toLowerCase());
      if (!matchSearch) return false;
      switch (filter) {
        case 'ongoing':
          return _isOngoing(c.status);
        case 'completed':
          return c.status == 'completed';
        case 'upcoming':
          return c.status == 'upcoming';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coursesAsync = ref.watch(studentCoursesProvider);
    final filter = ref.watch(courseFilterProvider);
    final searchQuery = ref.watch(courseSearchProvider);
    final totalCount =
        coursesAsync.maybeWhen(data: (d) => d.totalEnrolled, orElse: () => 0);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(studentCoursesProvider),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────
            _buildSliverAppBar(context, isDark, totalCount),

            // ── Search + Filters ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  children: [
                    _buildSearch(isDark),
                    const SizedBox(height: 14),
                    _buildFilterChips(filter, isDark),
                  ],
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: coursesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child:
                      Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(studentCoursesProvider),
                  ),
                ),
                data: (data) {
                  final filtered =
                      _applyFilters(data.courses, filter, searchQuery);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // stats grid
                        _buildStatsGrid(data, isDark),
                        const SizedBox(height: 20),

                        // count strip
                        Text(
                          '${filtered.length} courses',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // course list
                        if (filtered.isEmpty)
                          _emptyWidget(isDark)
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => _CourseCard(
                              course: filtered[i],
                              isDark: isDark,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
      BuildContext context, bool isDark, int count) {
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
                    'MY LEARNING',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'My Courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your learning journey',
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

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => ref.read(courseSearchProvider.notifier).state = v,
        style:
            TextStyle(fontSize: 14, color: isDark ? kText1Dark : kText1Light),
        decoration: InputDecoration(
          hintText: 'Search your courses…',
          hintStyle:
              TextStyle(fontSize: 14, color: isDark ? kText2Dark : kText3Light),
          prefixIcon:
              const Icon(Icons.search_rounded, color: kPrimary, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    ref.read(courseSearchProvider.notifier).state = '';
                    setState(() {});
                  },
                  child: Icon(Icons.close_rounded,
                      size: 17, color: isDark ? kText2Dark : kText3Light),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────────────────────
  Widget _buildFilterChips(String active, bool isDark) {
    final filters = [
      ('all', 'All Courses'),
      ('ongoing', 'Ongoing'),
      ('upcoming', 'Upcoming'),
      ('completed', 'Completed'),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = filters[i];
          final isActive = active == key;
          return GestureDetector(
            onTap: () => ref.read(courseFilterProvider.notifier).state = key,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? kPrimary : (isDark ? kSurfaceDark : kSurface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? kPrimary
                      : (isDark ? Colors.white.withOpacity(0.08) : kDivLight),
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isActive
                      ? Colors.white
                      : (isDark ? kText2Dark : kText2Light),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(StudentCoursesData data, bool isDark) {
    final stats = [
      _Stat(Icons.menu_book_rounded, '${data.totalEnrolled}', 'Enrolled'),
      _Stat(Icons.play_circle_rounded, '${data.ongoing}', 'Ongoing'),
      _Stat(Icons.check_circle_rounded, '${data.completed}', 'Done'),
      _Stat(Icons.schedule_rounded, '${data.upcoming}', 'Upcoming'),
    ];

    return Row(
      children: stats.map((s) {
        final isLast = s == stats.last;
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

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child:
                const Icon(Icons.menu_book_outlined, color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No Courses Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try a different filter or search term',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _Stat {
  final IconData icon;
  final String value, label;
  const _Stat(this.icon, this.value, this.label);
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
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
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: kPrimary, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isDark ? kText2Dark : kText3Light,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Course card ────────────────────────────────────────────────────────────────
class _CourseCard extends StatefulWidget {
  final StudentCourseItem course;
  final bool isDark;
  const _CourseCard({required this.course, required this.isDark});

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _statusColor {
    switch (widget.course.status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'upcoming':
        return const Color(0xFFF59E0B);
      default:
        return kPrimary;
    }
  }

  String get _statusLabel =>
      widget.course.status.replaceAll('-', ' ').toUpperCase();

  String? get _enrolledDate {
    final d = widget.course.enrolledAt;
    if (d == null) return null;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final isDark = widget.isDark;
    final prog = (c.progress / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/course-panel/${c.id}',
            extra: {'title': c.title, 'imageUrl': c.imageUrl});
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top row ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 62,
                        height: 62,
                        child: c.imageUrl != null && c.imageUrl!.isNotEmpty
                            ? Image.network(c.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _thumb())
                            : _thumb(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _statusColor.withOpacity(0.25)),
                            ),
                            child: Text(
                              _statusLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: _statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: -0.2,
                              color: isDark ? kText1Dark : kText1Light,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (c.instructor != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 12, color: kPrimary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    c.instructor!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: kPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_enrolledDate != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _enrolledDate!,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? kText2Dark : kText3Light,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
              ),

              // ── Progress + CTA ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  children: [
                    // progress row
                    Row(
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${c.progress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: kPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: prog,
                        minHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.08)
                            : kPrimaryBg,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(kPrimary),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // CTA
                    GestureDetector(
                      onTap: () =>
                          context.push('/course-panel/${c.id}', extra: {
                        'title': c.title,
                        'imageUrl': c.imageUrl,
                      }),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Continue Learning',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Icon(Icons.menu_book_rounded,
            color: Colors.white24, size: 28),
      );
}
