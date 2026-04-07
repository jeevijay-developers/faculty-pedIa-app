import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// ── Blue-600 palette (matches HomeScreen) ─────────────────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

class ExamContentTileScreen extends StatelessWidget {
  final String examType;
  const ExamContentTileScreen({super.key, required this.examType});

  String get examName {
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

  // Each tile: gradient pair + icon + label + route
  List<_TileData> get _tiles => [
        _TileData(
          icon: Icons.people_alt_rounded,
          label: 'Educators',
          subtitle: 'Top faculty',
          gradient: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
          onTap: (ctx) => ctx.push('/exam-educators/$examType'),
        ),
        _TileData(
          icon: Icons.live_tv_rounded,
          label: 'One To All',
          subtitle: 'Live Courses',
          gradient: [const Color(0xFF059669), const Color(0xFF047857)],
          onTap: (ctx) => ctx.push('/exam-courses/$examType/one-to-all'),
        ),
        _TileData(
          icon: Icons.person_pin_circle_rounded,
          label: 'One To One',
          subtitle: 'Live Courses',
          gradient: [const Color(0xFF0891B2), const Color(0xFF0E7490)],
          onTap: (ctx) => ctx.push('/exam-courses/$examType/one-to-one'),
        ),
        _TileData(
          icon: Icons.videocam_rounded,
          label: 'Webinars',
          subtitle: 'Watch & learn',
          gradient: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
          onTap: (ctx) => ctx.push('/exam-webinars/$examType'),
        ),
        _TileData(
          icon: Icons.assignment_rounded,
          label: 'Test Series',
          subtitle: 'Practice exams',
          gradient: [const Color(0xFFD97706), const Color(0xFFB45309)],
          onTap: (ctx) => ctx.go('/test-series?exam=$examType'),
        ),
        _TileData(
          icon: Icons.article_rounded,
          label: 'Posts',
          subtitle: 'Coming soon',
          gradient: [const Color(0xFF64748B), const Color(0xFF475569)],
          onTap: (ctx) => ctx.go('/posts?exam=$examType'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ModernTile(data: _tiles[i]),
                childCount: _tiles.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    // Exam-specific accent colors for the header
    final Map<String, List<Color>> headerGradients = {
      'iit-jee': [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
      'neet': [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
      'cbse': [const Color(0xFF059669), const Color(0xFF047857)],
    };
    final headerColors =
        headerGradients[examType.toLowerCase()] ?? [kPrimary, kPrimaryDark];

    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      backgroundColor: headerColors.first,
      surfaceTintColor: Colors.transparent,
      title: Text(
        '$examName Content',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
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
            // gradient bg
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // content (fade out on collapse to avoid overlap with title)
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
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
                            '$examName Content',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a category to get started',
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
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _TileData {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final void Function(BuildContext ctx) onTap;

  const _TileData({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });
}

// ── Tile widget ────────────────────────────────────────────────────────────────
class _ModernTile extends StatefulWidget {
  final _TileData data;
  const _ModernTile({required this.data});

  @override
  State<_ModernTile> createState() => _ModernTileState();
}

class _ModernTileState extends State<_ModernTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        d.onTap(context);
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: d.gradient.first.withOpacity(isDark ? 0.25 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // icon container
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: d.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(d.icon, color: Colors.white, size: 24),
                ),

                // label + subtitle + arrow row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          d.subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: d.gradient.first.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: d.gradient.first,
                          ),
                        ),
                      ],
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
