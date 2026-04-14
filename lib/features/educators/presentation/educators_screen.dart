import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/educator_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
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
final educatorsProvider =
    FutureProvider.autoDispose<List<Educator>>((ref) async {
  final api = ApiService();
  final response = await api.get('/api/educators');
  final data = response.data;

  List<dynamic> list = [];
  if (data is Map) {
    if (data['educators'] is List) {
      list = data['educators'] as List;
    } else if (data['data'] is Map && data['data']['educators'] is List) {
      list = data['data']['educators'] as List;
    }
  } else if (data is List) {
    list = data;
  }
  return list.map((e) => Educator.fromJson(e)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class EducatorsScreen extends ConsumerStatefulWidget {
  const EducatorsScreen({super.key});

  @override
  ConsumerState<EducatorsScreen> createState() => _EducatorsScreenState();
}

class _EducatorsScreenState extends ConsumerState<EducatorsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  String _examFilter = 'All Exams';

  static const _examFilters = ['All Exams', 'IIT-JEE', 'NEET', 'CBSE'];

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

  List<Educator> _applyFilters(List<Educator> list) {
    var result = list;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((e) =>
              e.displayName.toLowerCase().contains(q) ||
              e.displaySubjects.toLowerCase().contains(q) ||
              (e.bio?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (_examFilter != 'All Exams') {
      final target = _examFilter.toLowerCase();
      result = result
          .where((e) =>
              e.specialization.any((s) => s.toLowerCase().contains(target)))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final educatorsAsync = ref.watch(educatorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(educatorsProvider),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverToBoxAdapter(child: _buildSearchAndFilter(isDark)),
            SliverToBoxAdapter(
              child: educatorsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(
                    itemCount: 6,
                    itemHeight: 140,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: () => ref.invalidate(educatorsProvider),
                  ),
                ),
                data: (educators) {
                  final filtered = _applyFilters(educators);
                  if (educators.isEmpty) return _emptyWidget(isDark);
                  if (filtered.isEmpty) return _noResultsWidget(isDark);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCountStrip(educators, filtered, isDark),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) => _EducatorCard(
                          educator: filtered[i],
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
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
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
                        'FACULTY PEDIA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Educators',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Learn from India\'s finest faculty',
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
                    'Educators',
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
          // Search field
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
              onChanged: _onSearchChanged,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? kText1Dark : kText1Light,
              ),
              decoration: InputDecoration(
                hintText: 'Search educators, subjects…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? kText2Dark : kText3Light,
                ),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: kPrimary, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchDebounce?.cancel();
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

          // Exam filter chips — blue only, no rainbow
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _examFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _examFilters[i];
                final active = _examFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _examFilter = f),
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

  // ── Count strip ───────────────────────────────────────────────────────────
  Widget _buildCountStrip(
      List<Educator> all, List<Educator> filtered, bool isDark) {
    final activeCount = all.where((e) => e.status == 'active').length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Text(
            '${filtered.length} educators',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$activeCount active',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.people_outline_rounded,
                color: kPrimary, size: 34),
          ),
          const SizedBox(height: 16),
          const Text('No Educators Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check back later for new educators',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );

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

// ── Educator Card ──────────────────────────────────────────────────────────────
class _EducatorCard extends StatefulWidget {
  final Educator educator;
  final bool isDark;
  const _EducatorCard({required this.educator, required this.isDark});

  @override
  State<_EducatorCard> createState() => _EducatorCardState();
}

class _EducatorCardState extends State<_EducatorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  bool get _isActive => widget.educator.status == 'active';

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
    final e = widget.educator;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/educator/${e.id}');
      },
      onTapCancel: () => _ctrl.reverse(),
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
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Top Row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // avatar with blue border ring if active
                    Stack(
                      children: [
                        Container(
                          padding: _isActive
                              ? const EdgeInsets.all(2.5)
                              : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: _isActive
                                ? Border.all(color: kPrimary, width: 2)
                                : null,
                          ),
                          child: UserAvatar(
                            imageUrl: e.imageUrl,
                            name: e.displayName,
                            size: 64,
                            showBorder: false,
                          ),
                        ),
                        if (_isActive)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? kSurfaceDark : kSurface,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // name + star rating
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  e.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    color: isDark ? kText1Dark : kText1Light,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (e.rating != null) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 2),
                                Text(
                                  (e.rating!.average ?? 0).toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? kText1Dark : kText1Light,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 4),

                          // subjects — simple blue text, clean & classy
                          Text(
                            e.displaySubjects,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          // bio
                          if (e.bio != null && e.bio!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              e.bio!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.45,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Divider(
                    height: 1,
                    color: isDark ? Colors.white.withOpacity(0.07) : kDivLight),

                const SizedBox(height: 12),

                // ── Stats + CTA ───────────────────────────────────────
                Row(
                  children: [
                    _chip(Icons.people_rounded, '${e.followerCount} followers',
                        isDark),
                    const SizedBox(width: 14),
                    _chip(Icons.workspace_premium_rounded, e.displayExperience,
                        isDark),
                    const Spacer(),
                    // View Profile — blue outline style, clean
                    GestureDetector(
                      onTap: () => context.push('/educator/${e.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: kPrimaryBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kPrimaryMid),
                        ),
                        child: const Text(
                          'View Profile',
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, bool isDark) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDark ? kText2Dark : kText3Light),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? kText2Dark : kText2Light)),
        ],
      );
}
