import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/test_series_model.dart';
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

// ── Model ──────────────────────────────────────────────────────────────────────
class StudentTestSeriesItem {
  final TestSeries series;
  final int totalTests;
  final List<Test> tests;

  const StudentTestSeriesItem({
    required this.series,
    required this.totalTests,
    required this.tests,
  });
}

// ── Provider ───────────────────────────────────────────────────────────────────
final studentTestSeriesProvider =
    FutureProvider.autoDispose<List<StudentTestSeriesItem>>((ref) async {
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

  final rawSeries = data['testSeries'] ?? data['tests'];
  if (rawSeries is! List) return const [];

  final ids = <String>{};
  for (final entry in rawSeries) {
    if (entry is Map && entry['testSeriesId'] != null) {
      final rawId = entry['testSeriesId'];
      if (rawId is String) {
        ids.add(rawId);
      } else if (rawId is Map && rawId['_id'] != null) {
        ids.add(rawId['_id'].toString());
      }
    }
  }
  if (ids.isEmpty) return const [];

  final items = await Future.wait(ids.map((id) async {
    final r = await api.get('/api/test-series/$id');
    final p = r.data is Map<String, dynamic>
        ? r.data as Map<String, dynamic>
        : <String, dynamic>{};

    Map<String, dynamic> sd = {};
    if (p['testSeries'] is Map) {
      sd = Map<String, dynamic>.from(p['testSeries']);
    } else if (p['data'] is Map) {
      final nested = p['data'] as Map;
      sd = nested['testSeries'] is Map
          ? Map<String, dynamic>.from(nested['testSeries'])
          : Map<String, dynamic>.from(nested);
    } else {
      sd = Map<String, dynamic>.from(p);
    }

    final series = TestSeries.fromJson(sd);
    final tr = await api.get('/api/tests/test-series/$id',
        queryParameters: const {'limit': 200});
    final tp = tr.data is Map<String, dynamic>
        ? tr.data as Map<String, dynamic>
        : <String, dynamic>{};
    final td = tp['data'] is Map<String, dynamic>
        ? tp['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawTests = (td['tests'] ?? tp['tests']) is List
        ? (td['tests'] ?? tp['tests']) as List
        : const <dynamic>[];

    final apiTests = rawTests
        .whereType<Map<String, dynamic>>()
        .map(Test.fromJson)
        .where((t) => t.id.isNotEmpty)
        .toList();
    final seriesTests =
        (series.tests ?? const <Test>[]).where((t) => t.id.isNotEmpty).toList();
    final tests = apiTests.isNotEmpty ? apiTests : seriesTests;

    return StudentTestSeriesItem(
      series: series,
      totalTests: tests.isNotEmpty ? tests.length : (series.totalTests ?? 0),
      tests: tests,
    );
  }));

  return items.where((i) => i.series.id.isNotEmpty).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class StudentTestSeriesScreen extends ConsumerWidget {
  const StudentTestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = auth.user?.displayName?.split(' ').first ?? 'Student';
    final seriesAsync = ref.watch(studentTestSeriesProvider);
    final totalCount =
        seriesAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(studentTestSeriesProvider),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────
            _buildSliverAppBar(context, isDark, firstName, totalCount),

            SliverToBoxAdapter(
              child: seriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child:
                      Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(studentTestSeriesProvider),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) return _emptyWidget(isDark);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Text(
                          '${items.length} test series enrolled',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _TestSeriesCard(
                          item: items[i],
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
  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    String firstName,
    int count,
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
                    'MY TEST SERIES',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Hello, $firstName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ready to ace your next test?',
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

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.assignment_outlined,
                color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No test series yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Enroll in a test series to track your progress here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? kText2Dark : kText3Light,
              )),
        ]),
      );
}

// ── Test series card ───────────────────────────────────────────────────────────
class _TestSeriesCard extends StatefulWidget {
  final StudentTestSeriesItem item;
  final bool isDark;
  const _TestSeriesCard({required this.item, required this.isDark});

  @override
  State<_TestSeriesCard> createState() => _TestSeriesCardState();
}

class _TestSeriesCardState extends State<_TestSeriesCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final series = widget.item.series;
    final tests = widget.item.tests;
    final hasTests = tests.isNotEmpty;
    final isDark = widget.isDark;
    final desc = series.description?.isNotEmpty == true
        ? series.description!
        : 'Comprehensive test series to boost your preparation.';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // icon tile
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : kPrimaryBg,
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
                          Text(
                            series.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? kText1Dark : kText1Light,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: isDark ? kText2Dark : kText2Light,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // expand toggle
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kPrimaryBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 250),
                          turns: _expanded ? 0.0 : 0.5,
                          child: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: kPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // stats row
                Row(
                  children: [
                    _chip(Icons.quiz_rounded, '${widget.item.totalTests} Tests',
                        isDark),
                    const SizedBox(width: 12),
                    if (series.subject.isNotEmpty)
                      _chip(Icons.menu_book_rounded, series.subject.first,
                          isDark),
                  ],
                ),
              ],
            ),
          ),

          // ── Expanded tests ───────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOut,
            child: _expanded
                ? Column(
                    children: [
                      Divider(
                        height: 1,
                        color:
                            isDark ? Colors.white.withOpacity(0.07) : kDivLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: hasTests
                            ? Column(
                                children: tests
                                    .map((t) => _TestRow(
                                          test: t,
                                          isDark: isDark,
                                        ))
                                    .toList(),
                              )
                            : _EmptyNote(
                                seriesId: series.id,
                                isDark: isDark,
                              ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark) => Row(
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

// ── Individual test row ────────────────────────────────────────────────────────
class _TestRow extends StatefulWidget {
  final Test test;
  final bool isDark;
  const _TestRow({required this.test, required this.isDark});

  @override
  State<_TestRow> createState() => _TestRowState();
}

class _TestRowState extends State<_TestRow>
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
    final t = widget.test;
    final isDark = widget.isDark;
    final title = t.title?.isNotEmpty == true ? t.title! : 'Test';
    final sub = t.description?.isNotEmpty == true
        ? t.description!
        : 'Any student can attempt this test.';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (t.id.isNotEmpty) context.push('/live-test/${t.id}');
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? kBgDark : kBgLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
          ),
          child: Row(
            children: [
              // test number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.quiz_rounded, color: kPrimary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: isDark ? kText2Dark : kText2Light,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Start button
              GestureDetector(
                onTap: t.id.isEmpty
                    ? null
                    : () => context.push('/live-test/${t.id}'),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: t.id.isNotEmpty
                        ? kPrimary
                        : (isDark ? Colors.white.withOpacity(0.06) : kDivLight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: t.id.isNotEmpty
                        ? [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.28),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: t.id.isNotEmpty ? Colors.white : kText3Light,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Start',
                        style: TextStyle(
                          color: t.id.isNotEmpty ? Colors.white : kText3Light,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
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
}

// ── Empty note ─────────────────────────────────────────────────────────────────
class _EmptyNote extends StatelessWidget {
  final String seriesId;
  final bool isDark;
  const _EmptyNote({required this.seriesId, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kBgDark : kBgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: kPrimary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'No tests available in this series yet.',
              style: TextStyle(
                fontSize: 12,
                color: kText2Light,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/test-series/$seriesId'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: kPrimaryBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kPrimaryMid),
              ),
              child: const Text(
                'Details',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
