import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Provider ───────────────────────────────────────────────────────────────────
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
  return courses.where((c) => c.courseType == params.courseType).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class CourseTypeScreen extends ConsumerStatefulWidget {
  final String examType;
  final String courseType;

  const CourseTypeScreen({
    super.key,
    required this.examType,
    required this.courseType,
  });

  @override
  ConsumerState<CourseTypeScreen> createState() => _CourseTypeScreenState();
}

class _CourseTypeScreenState extends ConsumerState<CourseTypeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'Default';
  Timer? _searchDebounce;

  final _sortOptions = ['Default', 'Price: Low', 'Price: High', 'Popular'];

  // Exam-specific header gradient
  List<Color> get _headerGradient {
    switch (widget.examType.toLowerCase()) {
      case 'iit-jee':
        return [kPrimary, kPrimaryDark];
      case 'neet':
        return [const Color(0xFF7C3AED), const Color(0xFF5B21B6)];
      case 'cbse':
        return [const Color(0xFF059669), const Color(0xFF047857)];
      default:
        return [kPrimary, kPrimaryDark];
    }
  }

  String get _examLabel {
    switch (widget.examType.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      default:
        return widget.examType.toUpperCase();
    }
  }

  String get _courseTypeLabel => widget.courseType == 'one-to-one'
      ? 'One to One Live Courses'
      : 'One to All Live Courses';

  String get _courseTypeIcon => widget.courseType == 'one-to-one' ? '👤' : '👥';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value.trim());
    });
  }

  List<Course> _applyFilters(List<Course> courses) {
    var result = courses;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              (c.educator?.name?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    switch (_sortBy) {
      case 'Price: Low':
        result.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        break;
      case 'Price: High':
        result.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
        break;
      case 'Popular':
        result.sort(
            (a, b) => (b.enrolledCount ?? 0).compareTo(a.enrolledCount ?? 0));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final params = (examType: widget.examType, courseType: widget.courseType);
    final coursesAsync = ref.watch(courseTypeProvider(params));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: _headerGradient.first,
        onRefresh: () async => ref.invalidate(courseTypeProvider(params)),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────────
            _buildSliverAppBar(context, isDark),

            // ── Search + Sort ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSearchAndSort(isDark),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: coursesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(
                    itemCount: 5,
                    itemHeight: 110,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(courseTypeProvider(params)),
                  ),
                ),
                data: (courses) {
                  final filtered = _applyFilters(courses);

                  if (courses.isEmpty) {
                    return _emptyWidget(isDark);
                  }

                  if (filtered.isEmpty) {
                    return _noResultsWidget(isDark);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      _buildCountStrip(filtered.length, isDark),
                      // list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => _CourseListItem(
                          course: filtered[i],
                          isDark: isDark,
                          index: i,
                          headerGradient: _headerGradient,
                        ),
                      ),
                    ],
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
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    final g = _headerGradient;

    return SliverAppBar(
      expandedHeight: 155,
      pinned: true,
      elevation: 0,
      backgroundColor: g.first,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          children: [
            // gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: g,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // circles
            Positioned(right: -28, top: -28, child: _frostedCircle(140)),
            Positioned(left: -18, bottom: -36, child: _frostedCircle(110)),
            // content
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // breadcrumb
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _examLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.chevron_right_rounded,
                            color: Colors.white.withOpacity(0.5), size: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.courseType == 'one-to-one'
                              ? 'One To One'
                              : 'One To All',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _courseTypeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live sessions tailored for $_examLabel',
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
    );
  }

  // ── Search + Sort ─────────────────────────────────────────────────────────
  Widget _buildSearchAndSort(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          // search field
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _headerGradient.first.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search courses…',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: _headerGradient.first, size: 19),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                          child: Icon(Icons.close_rounded,
                              size: 17,
                              color: isDark
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8)),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // sort dropdown
          GestureDetector(
            onTap: () => _showSortSheet(context, isDark),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _sortBy != 'Default'
                    ? _headerGradient.first
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _sortBy != 'Default'
                      ? _headerGradient.first
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _headerGradient.first.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    size: 18,
                    color: _sortBy != 'Default'
                        ? Colors.white
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _sortBy == 'Default' ? 'Sort' : _sortBy,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _sortBy != 'Default'
                          ? Colors.white
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sort bottom sheet ─────────────────────────────────────────────────────
  void _showSortSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                if (_sortBy != 'Default')
                  GestureDetector(
                    onTap: () {
                      setState(() => _sortBy = 'Default');
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _headerGradient.first,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._sortOptions.map((opt) {
              final selected = _sortBy == opt;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortBy = opt);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? _headerGradient.first.withOpacity(0.1)
                        : (isDark
                            ? Colors.white.withOpacity(0.04)
                            : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? _headerGradient.first.withOpacity(0.3)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? _headerGradient.first
                              : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF374151)),
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(Icons.check_circle_rounded,
                            color: _headerGradient.first, size: 20),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Count strip ───────────────────────────────────────────────────────────
  Widget _buildCountStrip(int count, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _headerGradient.first.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_rounded,
                    color: _headerGradient.first, size: 13),
                const SizedBox(width: 5),
                Text(
                  '$count courses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _headerGradient.first,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty & no-results ────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _headerGradient.first.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(Icons.play_circle_outline_rounded,
                color: _headerGradient.first, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No Courses Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Check back later for new courses',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noResultsWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
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
          const Text('No results found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Try a different search or sort',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
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

// ── Course List Item ───────────────────────────────────────────────────────────
class _CourseListItem extends StatefulWidget {
  final Course course;
  final bool isDark;
  final int index;
  final List<Color> headerGradient;

  const _CourseListItem({
    required this.course,
    required this.isDark,
    required this.index,
    required this.headerGradient,
  });

  @override
  State<_CourseListItem> createState() => _CourseListItemState();
}

class _CourseListItemState extends State<_CourseListItem>
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

  bool get _isFree =>
      widget.course.fees == null || widget.course.finalPrice <= 0;

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    return url.startsWith('/')
        ? '${AppConfig.baseUrl}$url'
        : '${AppConfig.baseUrl}/$url';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final isDark = widget.isDark;
    final g = widget.headerGradient;
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: g.first.withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Thumbnail ──────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 110,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallbackThumb(g),
                            )
                          : _fallbackThumb(g),
                    ),
                    // overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // play icon
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    // free badge
                    if (_isFree)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // specialization pill
                      if (c.specialization.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: g.first.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.specialization.first,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: g.first,
                            ),
                          ),
                        ),

                      // title
                      Text(
                        c.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          height: 1.3,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 6),

                      // educator
                      if (c.educator?.name != null)
                        Row(
                          children: [
                            Icon(Icons.person_rounded,
                                size: 12, color: g.first),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.educator!.name!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: g.first,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 10),

                      // price + arrow
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _isFree ? 'Free' : '₹${c.finalPrice.toInt()}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color:
                                  _isFree ? const Color(0xFF16A34A) : kPrimary,
                            ),
                          ),
                          if (!_isFree &&
                              c.discount != null &&
                              c.discount! > 0) ...[
                            const SizedBox(width: 6),
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
                          ],
                          const Spacer(),
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: g,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
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

  Widget _fallbackThumb(List<Color> g) {
    return Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            g.first.withOpacity(0.3),
            g.last.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_rounded,
          size: 36,
          color: g.first.withOpacity(0.5),
        ),
      ),
    );
  }
}
