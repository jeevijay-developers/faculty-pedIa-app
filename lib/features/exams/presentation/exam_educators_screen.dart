import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/educator_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// ── Blue-600 palette (consistent with HomeScreen & ExamContentTile) ────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Provider ───────────────────────────────────────────────────────────────────
final examEducatorsProvider = FutureProvider.family
    .autoDispose<List<Educator>, String>((ref, examType) async {
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
  final specialization = specializationForApi(examType);
  final response =
      await api.get('/api/educators/specialization/$specialization');
  final data = response.data;

  List<dynamic> educatorsList = [];
  if (data is Map &&
      data['data'] != null &&
      data['data']['educators'] != null) {
    educatorsList = data['data']['educators'] as List;
  } else if (data is Map && data['educators'] != null) {
    educatorsList = data['educators'] as List;
  } else if (data is List) {
    educatorsList = data;
  }

  return educatorsList.map((e) => Educator.fromJson(e)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class ExamEducatorsScreen extends ConsumerWidget {
  final String examType;
  const ExamEducatorsScreen({super.key, required this.examType});

  String get _title {
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

  // Exam-specific gradient (mirrors ExamContentTile colours)
  List<Color> get _headerGradient {
    switch (examType.toLowerCase()) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educatorsAsync = ref.watch(examEducatorsProvider(examType));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(examEducatorsProvider(examType)),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: educatorsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(itemCount: 6, itemHeight: 140),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(examEducatorsProvider(examType)),
                  ),
                ),
                data: (educators) {
                  if (educators.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 80),
                      child: EmptyStateWidget(
                        icon: Icons.people_outline_rounded,
                        title: 'No Educators Found',
                        subtitle: 'Check back later for new educators',
                      ),
                    );
                  }
                  return _EducatorList(
                    educators: educators,
                    isDark: isDark,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    final g = _headerGradient;

    return SliverAppBar(
      expandedHeight: 155,
      pinned: true,
      elevation: 0,
      backgroundColor: g.first,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '$_title Educators',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
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
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          children: [
            // gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: g,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: _frostedCircle(160),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: _frostedCircle(120),
            ),
            // text content (fade out on collapse to avoid overlap with title)
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Builder(
                builder: (context) {
                  final settings = context.dependOnInheritedWidgetOfExactType<
                      FlexibleSpaceBarSettings>();
                  final extent = settings?.currentExtent ?? 0;
                  final minExtent = settings?.minExtent ?? 0;
                  final maxExtent = settings?.maxExtent ?? 1;
                  final t = ((extent - minExtent) / (maxExtent - minExtent))
                      .clamp(0.0, 1.0);

                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - t)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Exam Preparation',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_title Educators',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Learn from the best in the field',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
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

  Widget _frostedCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
      );
}

// ── List wrapper (count pill + ListView) ──────────────────────────────────────
class _EducatorList extends StatelessWidget {
  final List<Educator> educators;
  final bool isDark;
  const _EducatorList({required this.educators, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // count pill
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people_rounded, color: kPrimary, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${educators.length} Educators',
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
        // cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          itemCount: educators.length,
          itemBuilder: (context, index) => _EducatorCard(
            educator: educators[index],
            isDark: isDark,
          ),
        ),
      ],
    );
  }
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

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isActive => widget.educator.status == 'active';

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
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withOpacity(isDark ? 0.12 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── top row: avatar + info ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // avatar with active ring
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: _isActive
                                ? const LinearGradient(
                                    colors: [kPrimary, kPrimaryLight],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: _isActive ? null : Colors.transparent,
                          ),
                          child: UserAvatar(
                            imageUrl: e.imageUrl,
                            name: e.displayName,
                            size: 68,
                            showBorder: false,
                          ),
                        ),
                        if (_isActive)
                          Positioned(
                            bottom: 3,
                            right: 3,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // name + subjects + bio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // name + rating row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  e.displayName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (e.rating != null) ...[
                                const SizedBox(width: 6),
                                _RatingPill(
                                  rating: e.rating!.average ?? 0,
                                  count: e.rating!.count,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 5),

                          // subjects pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kPrimaryBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_book_rounded,
                                    size: 11, color: kPrimary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    e.displaySubjects,
                                    style: const TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // bio
                          if (e.bio != null && e.bio!.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(
                              e.bio!,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
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

                // ── divider ────────────────────────────────────────────────
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.06),
                ),

                const SizedBox(height: 12),

                // ── bottom stats row ───────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.people_rounded,
                      label: '${e.followerCount} followers',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.workspace_premium_rounded,
                      label: e.displayExperience,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    // View profile button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [kPrimary, kPrimaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
}

// ── Small stat chip ────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _StatChip(
      {required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ── Inline rating pill (replaces RatingWidget in the card header) ─────────────
class _RatingPill extends StatelessWidget {
  final double rating;
  final int? count;
  const _RatingPill({required this.rating, this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 11, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 2),
            Text(
              '($count)',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFFD97706),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
