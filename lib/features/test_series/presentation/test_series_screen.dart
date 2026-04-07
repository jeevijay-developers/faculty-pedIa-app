import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/test_series_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

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

// ── Provider ───────────────────────────────────────────────────────────────────
final testSeriesProvider = FutureProvider.family
    .autoDispose<List<TestSeries>, String?>((ref, examType) async {
  final api = ApiService();
  final response = await api.get('/api/test-series');
  final data = response.data;

  List<dynamic> list = [];
  if (data is Map && data['testSeries'] != null) {
    list = data['testSeries'] as List;
  } else if (data is List) {
    list = data;
  }
  return list.map((e) => TestSeries.fromJson(e)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class TestSeriesScreen extends ConsumerStatefulWidget {
  final String? examType;

  const TestSeriesScreen({super.key, this.examType});

  @override
  ConsumerState<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends ConsumerState<TestSeriesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  static const _filters = ['All', 'Free', 'Paid', 'Popular'];

  String? get _examLabel {
    final type = widget.examType;
    if (type == null || type.isEmpty) return null;
    switch (type.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      case 'upsc':
        return 'UPSC';
      default:
        return type.toUpperCase();
    }
  }

  bool _matchesExam(TestSeries series, String label) {
    final target = label.toLowerCase();
    final inSpecialization =
        series.specialization.any((s) => s.toLowerCase().contains(target));
    final inSubject =
        series.subject.any((s) => s.toLowerCase().contains(target));
    final inTitle = series.title.toLowerCase().contains(target);
    return inSpecialization || inSubject || inTitle;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TestSeries> _applyFilters(List<TestSeries> series) {
    var result = series;

    final examLabel = _examLabel;
    if (examLabel != null) {
      result = result.where((s) => _matchesExam(s, examLabel)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((s) =>
              s.title.toLowerCase().contains(q) ||
              (s.educatorName?.toLowerCase().contains(q) ?? false) ||
              s.subject.any((sub) => sub.toLowerCase().contains(q)))
          .toList();
    }

    switch (_activeFilter) {
      case 'Free':
        result = result.where((s) => s.fees == null || s.fees == 0).toList();
        break;
      case 'Paid':
        result = result.where((s) => s.fees != null && s.fees! > 0).toList();
        break;
      case 'Popular':
        result = result.where((s) => (s.enrolledCount ?? 0) >= 10).toList();
        break;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(testSeriesProvider(widget.examType));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async =>
            ref.invalidate(testSeriesProvider(widget.examType)),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverToBoxAdapter(child: _buildSearchAndFilter(isDark)),
            SliverToBoxAdapter(
              child: seriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(itemCount: 5, itemHeight: 180),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(testSeriesProvider(widget.examType)),
                  ),
                ),
                data: (series) {
                  final filtered = _applyFilters(series);

                  if (series.isEmpty) {
                    return _emptyWidget(isDark);
                  }
                  if (filtered.isEmpty) {
                    return _noResultsWidget(isDark);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(
                          '${filtered.length} test series found',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? kText2Dark : kText3Light,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _TestSeriesCard(
                          series: filtered[i],
                          isDark: isDark,
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
    final examLabel = _examLabel;
    return SliverAppBar(
      expandedHeight: 145,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            if (context.canPop())
              context.pop();
            else
              context.go('/home');
          },
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
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isCollapsed = constraints.maxHeight <= kToolbarHeight + 24;

          return FlexibleSpaceBar(
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
                // one subtle circle — minimal
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
                        'PRACTICE & IMPROVE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Test Series',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        examLabel == null
                            ? 'Sharpen your skills with mock exams'
                            : 'Sharpen your skills with $examLabel tests',
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
            title: isCollapsed
                ? const Text(
                    'Test Series',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  )
                : null,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          );
        },
      ),
    );
  }

  // ── Search + Filter ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          // search field
          Container(
            height: 48,
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
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? kText1Dark : kText1Light,
              ),
              decoration: InputDecoration(
                hintText: 'Search test series…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? kText2Dark : kText3Light,
                ),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kPrimary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.close_rounded,
                            size: 17, color: isDark ? kText2Dark : kText3Light),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // filter chips — blue only
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _filters[i];
                final active = _activeFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? kPrimary
                          : (isDark ? kSurfaceDark : kSurface),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? kPrimary
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : kDivLight),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : (isDark ? kText2Dark : kText2Light),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty / No results ────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) {
    final examLabel = _examLabel;
    final title = examLabel == null
        ? 'No Test Series Available'
        : 'No $examLabel Test Series';

    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
              color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
          child:
              const Icon(Icons.assignment_outlined, color: kPrimary, size: 34),
        ),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('Check back later for new test series',
            style: TextStyle(
                fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
      ]),
    );
  }

  Widget _noResultsWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child:
                const Icon(Icons.search_off_rounded, color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No results found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try a different search or filter',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );
}

// ── Test Series Card ───────────────────────────────────────────────────────────
class _TestSeriesCard extends StatefulWidget {
  final TestSeries series;
  final bool isDark;

  const _TestSeriesCard({required this.series, required this.isDark});

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

  bool get _isFree => widget.series.fees == null || widget.series.fees == 0;

  String get _priceLabel {
    if (_isFree) return 'Free';
    final d = widget.series.discount;
    if (d != null && d > 0) {
      final orig = widget.series.fees!;
      final final_ = orig - (orig * d / 100);
      return '₹${final_.toInt()}';
    }
    return '₹${widget.series.fees!.toInt()}';
  }

  String? get _originalPrice {
    final d = widget.series.discount;
    if (!_isFree && d != null && d > 0) {
      return '₹${widget.series.fees!.toInt()}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.series;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/test-series/${s.id}');
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // blue icon tile — single color, no rainbow
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: kPrimaryBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kPrimaryMid),
                      ),
                      child: const Icon(
                        Icons.assignment_rounded,
                        color: kPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // title + free badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  s.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    height: 1.3,
                                    color: isDark ? kText1Dark : kText1Light,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_isFree) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFF86EFAC)),
                                  ),
                                  child: const Text(
                                    'Free',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          // educator name — blue text, no pill
                          if (s.educatorName != null)
                            Row(
                              children: [
                                const Icon(Icons.person_rounded,
                                    size: 12, color: kPrimary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'By ${s.educatorName}',
                                    style: const TextStyle(
                                      fontSize: 12,
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
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──────────────────────────────────────────────
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
              ),

              // ── Stats row ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _chip(Icons.quiz_rounded, '${s.totalTests ?? 0} Tests',
                        isDark),
                    const SizedBox(width: 12),
                    _chip(Icons.people_rounded,
                        '${s.enrolledCount ?? 0} Enrolled', isDark),
                    if (s.subject.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      _chip(Icons.menu_book_rounded, s.subject.first, isDark),
                    ],
                  ],
                ),
              ),

              // ── Subject chips (extra) ──────────────────────────────────
              if (s.subject.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: s.subject.skip(1).take(3).map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : kDivLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          sub,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // ── Bottom CTA ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.02) : kBgLight,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isFree && _originalPrice != null)
                          Text(
                            _originalPrice!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white24 : kText3Light,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          _priceLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: _isFree ? const Color(0xFF16A34A) : kPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // CTA button — solid blue, no gradient
                    GestureDetector(
                      onTap: () => context.push('/test-series/${s.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 11),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
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
                            Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 14),
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

  Widget _chip(IconData icon, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: isDark ? kText2Dark : kText3Light),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? kText2Dark : kText2Light,
          ),
        ),
      ],
    );
  }
}
