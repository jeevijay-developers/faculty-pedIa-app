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

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Provider ───────────────────────────────────────────────────────────────────
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

// ── Screen ─────────────────────────────────────────────────────────────────────
class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          _buildSliverAppBar(context, isDark),
        ],
        body: Column(
          children: [
            // ── Search + Filter ──────────────────────────────────────────
            _buildSearchAndFilter(isDark),
            // ── Tab Content ──────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CoursesTab(
                    coursesAsync: coursesAsync,
                    courseType: 'one-to-all',
                    searchQuery: _searchQuery,
                    isDark: isDark,
                    onRefresh: () => ref.invalidate(coursesProvider),
                  ),
                  _CoursesTab(
                    coursesAsync: coursesAsync,
                    courseType: 'one-to-one',
                    searchQuery: _searchQuery,
                    isDark: isDark,
                    onRefresh: () => ref.invalidate(coursesProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 170,
      toolbarHeight: 56,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      actions: const [],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          children: [
            // gradient bg
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // decorative circles
            Positioned(
              right: -24,
              top: -24,
              child: _frostedCircle(130),
            ),
            Positioned(
              left: -16,
              bottom: -30,
              child: _frostedCircle(100),
            ),
            // content
            Positioned(
              left: 20,
              right: 20,
              bottom: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Courses',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Live & recorded sessions for every exam',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          const Text(
            'Courses',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _tabController.index == 0 ? 'One To All' : 'One To One',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: kPrimary,
              unselectedLabelColor: Colors.white.withOpacity(0.8),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              unselectedLabelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: 'One To All'),
                Tab(text: 'One To One'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Search + Filter ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilter(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Search field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: kPrimary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search courses, educators…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kPrimary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _frostedCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
      );
}

// ── Courses Tab ────────────────────────────────────────────────────────────────
class _CoursesTab extends StatelessWidget {
  final AsyncValue<List<Course>> coursesAsync;
  final String courseType;
  final String searchQuery;
  final bool isDark;
  final VoidCallback onRefresh;

  const _CoursesTab({
    required this.coursesAsync,
    required this.courseType,
    required this.searchQuery,
    required this.isDark,
    required this.onRefresh,
  });

  bool _matchesCourseType(String? value, String target) {
    if (value == null || value.isEmpty) return false;
    final n = value.toLowerCase();
    if (target == 'one-to-one') return n == 'one-to-one' || n == 'oto';
    if (target == 'one-to-all') return n == 'one-to-all' || n == 'ota';
    return n == target;
  }

  List<Course> _applyFilters(List<Course> courses) {
    var result = courses
        .where((c) => _matchesCourseType(c.courseType, courseType))
        .toList();

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result.where((c) {
        return c.title.toLowerCase().contains(q) ||
            (c.educator?.name?.toLowerCase().contains(q) ?? false) ||
            c.specialization.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: kPrimary,
      onRefresh: () async => onRefresh(),
      child: coursesAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(itemCount: 4, itemHeight: 260),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorStateWidget(
            message: error.toString(),
            onRetry: onRefresh,
          ),
        ),
        data: (courses) {
          final filtered = _applyFilters(courses);

          if (courses
              .where((c) => _matchesCourseType(c.courseType, courseType))
              .isEmpty) {
            return EmptyStateWidget(
              icon: Icons.play_circle_outline_rounded,
              title: 'No Courses Available',
              subtitle: courseType == 'one-to-one'
                  ? 'No one-to-one courses available yet'
                  : 'No one-to-all courses available yet',
            );
          }

          if (filtered.isEmpty) {
            return _NoResultsWidget(isDark: isDark);
          }

          return Column(
            children: [
              // count pill
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: kPrimaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_rounded,
                              color: kPrimary, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            '${filtered.length} courses',
                            style: const TextStyle(
                              color: kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _CourseCard(
                    course: filtered[index],
                    isDark: isDark,
                    index: index,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Course Card ────────────────────────────────────────────────────────────────
class _CourseCard extends StatefulWidget {
  final Course course;
  final bool isDark;
  final int index;

  const _CourseCard({
    required this.course,
    required this.isDark,
    required this.index,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  // Color pool matching other screens
  static const _gradients = [
    [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    [Color(0xFF7C3AED), Color(0xFF5B21B6)],
    [Color(0xFF059669), Color(0xFF047857)],
    [Color(0xFFD97706), Color(0xFFB45309)],
    [Color(0xFFDC2626), Color(0xFFB91C1C)],
    [Color(0xFF0891B2), Color(0xFF0E7490)],
  ];

  List<Color> get _gradient => _gradients[widget.index % _gradients.length];

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

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    return url.startsWith('/')
        ? '${AppConfig.baseUrl}$url'
        : '${AppConfig.baseUrl}/$url';
  }

  bool get _isFree =>
      widget.course.fees == null || widget.course.finalPrice <= 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final isDark = widget.isDark;
    final imageUrl = _resolveImageUrl(c.imageUrl);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/course/${c.id}');
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withOpacity(isDark ? 0.15 : 0.1),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: Stack(
                  children: [
                    // image / placeholder
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(),
                            )
                          : _imageFallback(),
                    ),
                    // gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // course-type badge (top-left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gradient.first,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.courseType?.toLowerCase() == 'one-to-one'
                              ? 'One To One'
                              : 'One To All',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // free / paid badge (top-right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isFree
                              ? const Color(0xFF16A34A)
                              : Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isFree ? 'Free' : '₹${c.finalPrice.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    // play icon (center)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1.5),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Card Body ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // specialization pills
                    if (c.specialization.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: c.specialization
                            .take(2)
                            .map((spec) => _SpecPill(
                                  label: spec,
                                  color: _gradient.first,
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                    const SizedBox(height: 10),

                    // title
                    Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // educator row
                    if (c.educator != null)
                      Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _gradient.first.withOpacity(0.4),
                                  width: 1.5),
                            ),
                            child: ClipOval(
                              child: UserAvatar(
                                imageUrl: c.educator!.profilePicture,
                                name: c.educator!.name,
                                size: 30,
                                showBorder: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.educator!.name ?? 'Educator',
                              style: TextStyle(
                                color: _gradient.first,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // enrolled count
                          if (c.enrolledCount != null && c.enrolledCount! > 0)
                            Row(
                              children: [
                                Icon(Icons.people_rounded,
                                    size: 13,
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.enrolledCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                    const SizedBox(height: 14),

                    // ── Bottom divider + CTA ──────────────────────────
                    Divider(
                      height: 1,
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.black.withOpacity(0.05),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        // price block
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!_isFree &&
                                c.discount != null &&
                                c.discount! > 0)
                              Text(
                                '₹${c.fees!.toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFCBD5E1),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              _isFree ? 'Free' : '₹${c.finalPrice.toInt()}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: _isFree
                                    ? const Color(0xFF16A34A)
                                    : kPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // View Details button
                        GestureDetector(
                          onTap: () => context.push('/course/${c.id}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _gradient.first.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _imageFallback() {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gradient.first.withOpacity(0.3),
            _gradient.last.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_rounded,
          size: 52,
          color: _gradient.first.withOpacity(0.5),
        ),
      ),
    );
  }
}

// ── Spec Pill ──────────────────────────────────────────────────────────────────
class _SpecPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _SpecPill(
      {required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── No Results Widget ──────────────────────────────────────────────────────────
class _NoResultsWidget extends StatelessWidget {
  final bool isDark;
  const _NoResultsWidget({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kPrimaryBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                const Icon(Icons.search_off_rounded, color: kPrimary, size: 34),
          ),
          const SizedBox(height: 16),
          const Text(
            'No courses found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different search or filter',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
