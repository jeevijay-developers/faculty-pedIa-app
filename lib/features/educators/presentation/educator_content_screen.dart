import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/models/test_series_model.dart';
import 'educator_profile_screen.dart';

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

// ── Screen ─────────────────────────────────────────────────────────────────────
class EducatorContentScreen extends ConsumerStatefulWidget {
  final String educatorId;
  final int initialTabIndex;

  const EducatorContentScreen({
    super.key,
    required this.educatorId,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<EducatorContentScreen> createState() =>
      _EducatorContentScreenState();
}

class _EducatorContentScreenState extends ConsumerState<EducatorContentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final educatorAsync = ref.watch(educatorDetailProvider(widget.educatorId));
    final educatorName = educatorAsync.maybeWhen(
      data: (e) => e.displayName,
      orElse: () => 'Educator',
    );

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          // ── Collapsible AppBar ─────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: kPrimary,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
            title: Text(
              educatorName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(44),
              child: Container(
                color: kPrimary,
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.55),
                  indicatorColor: Colors.white,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Courses'),
                    Tab(text: 'Webinars'),
                    Tab(text: 'Tests'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _CoursesTab(educatorId: widget.educatorId, isDark: isDark),
            _WebinarsTab(educatorId: widget.educatorId, isDark: isDark),
            _TestSeriesTab(educatorId: widget.educatorId, isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Courses tab ────────────────────────────────────────────────────────────────
class _CoursesTab extends ConsumerStatefulWidget {
  final String educatorId;
  final bool isDark;
  const _CoursesTab({required this.educatorId, required this.isDark});

  @override
  ConsumerState<_CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<_CoursesTab> {
  _CourseFilter _filter = _CourseFilter.all;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(educatorCoursesProvider(widget.educatorId));
    final isDark = widget.isDark;

    return async.when(
      loading: () => _loadingWidget(),
      error: (e, _) => _emptyWidget('Failed to load courses', isDark),
      data: (courses) {
        final oto = courses
            .where((c) => c.courseType == 'one-to-one' || c.courseType == 'OTO')
            .toList();
        final ota = courses
            .where((c) => c.courseType == 'one-to-all' || c.courseType == 'OTA')
            .toList();

        final showOto =
            _filter == _CourseFilter.all || _filter == _CourseFilter.oto;
        final showOta =
            _filter == _CourseFilter.all || _filter == _CourseFilter.ota;
        final hasAny =
            (showOto && oto.isNotEmpty) || (showOta && ota.isNotEmpty);

        if (!hasAny) return _emptyWidget('No courses yet', isDark);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // filter chips
            _FilterRow(
              filter: _filter,
              isDark: isDark,
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 16),

            if (showOto && oto.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.person_rounded,
                title: 'One to One',
                subtitle: 'Personalized live sessions',
                count: oto.length,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ...oto.map((c) => _CourseCard(course: c, isDark: isDark)),
              const SizedBox(height: 8),
            ],

            if (showOta && ota.isNotEmpty) ...[
              _SectionHeader(
                icon: Icons.groups_rounded,
                title: 'One to All',
                subtitle: 'Interactive group classes',
                count: ota.length,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              ...ota.map((c) => _CourseCard(course: c, isDark: isDark)),
            ],
          ],
        );
      },
    );
  }
}

// ── Webinars tab ───────────────────────────────────────────────────────────────
class _WebinarsTab extends ConsumerWidget {
  final String educatorId;
  final bool isDark;
  const _WebinarsTab({required this.educatorId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorWebinarsProvider(educatorId));

    return async.when(
      loading: () => _loadingWidget(),
      error: (e, _) => _emptyWidget('Failed to load webinars', isDark),
      data: (webinars) {
        if (webinars.isEmpty) return _emptyWidget('No webinars yet', isDark);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _CountStrip(
                count: webinars.length, label: 'webinars', isDark: isDark),
            const SizedBox(height: 12),
            ...webinars.map((w) => _WebinarCard(webinar: w, isDark: isDark)),
          ],
        );
      },
    );
  }
}

// ── Test series tab ────────────────────────────────────────────────────────────
class _TestSeriesTab extends ConsumerWidget {
  final String educatorId;
  final bool isDark;
  const _TestSeriesTab({required this.educatorId, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorTestSeriesProvider(educatorId));

    return async.when(
      loading: () => _loadingWidget(),
      error: (e, _) => _emptyWidget('Failed to load test series', isDark),
      data: (series) {
        if (series.isEmpty) return _emptyWidget('No test series yet', isDark);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _CountStrip(
                count: series.length, label: 'test series', isDark: isDark),
            const SizedBox(height: 12),
            ...series
                .map((ts) => _TestSeriesCard(testSeries: ts, isDark: isDark)),
          ],
        );
      },
    );
  }
}

// ── Course card ────────────────────────────────────────────────────────────────
class _CourseCard extends StatefulWidget {
  final Course course;
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

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final isDark = widget.isDark;
    final imgUrl = _resolveUrl(c.imageUrl);
    final isFree = c.fees == null || c.finalPrice <= 0;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/course/${c.id}');
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imgUrl.isNotEmpty
                      ? Image.network(imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _courseFallback())
                      : _courseFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // type pill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : kPrimaryBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c.courseType == 'one-to-one' ||
                                    c.courseType == 'OTO'
                                ? '1:1 Live'
                                : '1:All Live',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: -0.2,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    if (c.subject.isNotEmpty)
                      Text(
                        c.subject.take(2).join(' · '),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? kText2Dark : kText2Light,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          isFree ? 'Free' : '₹${c.finalPrice.toInt()}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isFree ? const Color(0xFF16A34A) : kPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (!isFree &&
                            c.discount != null &&
                            c.discount! > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹${c.fees!.toInt()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? kText2Dark : kText3Light,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: kPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _courseFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child:
              Icon(Icons.play_circle_rounded, color: Colors.white24, size: 28),
        ),
      );
}

// ── Webinar card ───────────────────────────────────────────────────────────────
class _WebinarCard extends StatefulWidget {
  final dynamic webinar;
  final bool isDark;
  const _WebinarCard({required this.webinar, required this.isDark});

  @override
  State<_WebinarCard> createState() => _WebinarCardState();
}

class _WebinarCardState extends State<_WebinarCard>
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

  @override
  Widget build(BuildContext context) {
    final w = widget.webinar;
    final isDark = widget.isDark;
    final title = w['title'] ?? 'Webinar';
    final date = w['scheduledAt'] ?? w['date'] ?? '';
    final img = w['imageUrl'] ?? w['thumbnail'] ?? '';
    final id = w['_id'] ?? w['id'] ?? '';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (id.isNotEmpty) context.push('/webinar/$id');
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: img.isNotEmpty
                      ? Image.network(img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _webinarFallback())
                      : _webinarFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : kPrimaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Webinar',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          )),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.1,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded,
                              size: 12, color: kPrimary),
                          const SizedBox(width: 4),
                          Text(
                            _fmtDate(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? kText2Dark : kText2Light,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: kPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }

  Widget _webinarFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 26),
        ),
      );
}

// ── Test series card ───────────────────────────────────────────────────────────
class _TestSeriesCard extends StatefulWidget {
  final TestSeries testSeries;
  final bool isDark;
  const _TestSeriesCard({required this.testSeries, required this.isDark});

  @override
  State<_TestSeriesCard> createState() => _TestSeriesCardState();
}

class _TestSeriesCardState extends State<_TestSeriesCard>
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

  @override
  Widget build(BuildContext context) {
    final ts = widget.testSeries;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/test-series/${ts.id}');
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // icon tile
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kPrimaryMid),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: kPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : kPrimaryBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Test Series',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          )),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ts.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.1,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.quiz_rounded,
                            size: 12, color: isDark ? kText2Dark : kText3Light),
                        const SizedBox(width: 4),
                        Text(
                          '${ts.totalTests ?? 0} Tests',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                        if (ts.subject.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.menu_book_rounded,
                              size: 12,
                              color: isDark ? kText2Dark : kText3Light),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ts.subject.first,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: kPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared UI helpers ──────────────────────────────────────────────────────────

/// Blue count strip shown above list
class _CountStrip extends StatelessWidget {
  final int count;
  final String label;
  final bool isDark;
  const _CountStrip({
    required this.count,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count $label found',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: isDark ? kText2Dark : kText2Light,
      ),
    );
  }
}

/// Filter row for Courses tab
enum _CourseFilter { all, oto, ota }

class _FilterRow extends StatelessWidget {
  final _CourseFilter filter;
  final bool isDark;
  final ValueChanged<_CourseFilter> onChanged;
  const _FilterRow({
    required this.filter,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('All', _CourseFilter.all),
        const SizedBox(width: 8),
        _chip('One to One', _CourseFilter.oto),
        const SizedBox(width: 8),
        _chip('One to All', _CourseFilter.ota),
      ],
    );
  }

  Widget _chip(String label, _CourseFilter value) {
    final active = filter == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? kPrimary : (isDark ? kSurfaceDark : kSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? kPrimary
                : (isDark ? Colors.white.withOpacity(0.08) : kDivLight),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : (isDark ? kText2Dark : kText2Light),
          ),
        ),
      ),
    );
  }
}

/// Section header with icon, title, subtitle, count badge
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final int count;
  final bool isDark;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: kPrimary, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? kText1Dark : kText1Light,
                  )),
              Text(subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? kText2Dark : kText2Light,
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kPrimaryMid),
          ),
          child: Text('$count',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kPrimary,
              )),
        ),
      ],
    );
  }
}

/// Empty / error state
Widget _emptyWidget(String message, bool isDark) => Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: kPrimaryBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.inbox_rounded, color: kPrimary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? kText1Dark : kText1Light,
                )),
          ],
        ),
      ),
    );

/// Centered loading indicator
Widget _loadingWidget() => const Center(
      child: CircularProgressIndicator(color: kPrimary),
    );

// ── Helpers ────────────────────────────────────────────────────────────────────
String _resolveUrl(String url) {
  if (url.isEmpty) return '';
  final uri = Uri.tryParse(url);
  if (uri == null) return '';
  if (uri.hasScheme) return url;
  return url.startsWith('/')
      ? '${AppConfig.baseUrl}$url'
      : '${AppConfig.baseUrl}/$url';
}
