import 'package:flutter/material.dart';
import '../shared/models/hamburger_model.dart';

// Following skeleton shown while data is loading.
class FollowingTabSkeleton extends StatelessWidget {
  const FollowingTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      drawer: const HamburgerDrawer(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            surfaceTintColor: Colors.transparent,
            leading: Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
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
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                      children: const [
                        _SkeletonLine(width: 170, height: 10, radius: 6),
                        SizedBox(height: 6),
                        _SkeletonLine(width: 140, height: 22, radius: 10),
                        SizedBox(height: 6),
                        _SkeletonLine(width: 130, height: 12, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: const _SkeletonLine(
                  width: double.infinity, height: 46, radius: 14),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: const _SkeletonLine(width: 140, height: 12, radius: 6),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                children: const [
                  _SkeletonFollowingCard(),
                  SizedBox(height: 12),
                  _SkeletonFollowingCard(),
                  SizedBox(height: 12),
                  _SkeletonFollowingCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonFollowingCard extends StatelessWidget {
  const _SkeletonFollowingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SkeletonLine(width: 54, height: 54, radius: 27),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(width: 160, height: 12, radius: 6),
                      SizedBox(height: 6),
                      _SkeletonLine(width: 110, height: 10, radius: 6),
                      SizedBox(height: 6),
                      _SkeletonLine(width: 80, height: 10, radius: 6),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                _SkeletonLine(width: 30, height: 30, radius: 9),
              ],
            ),
          ),
          _SkeletonDivider(),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                    child: _SkeletonLine(
                        width: double.infinity, height: 34, radius: 12)),
                SizedBox(width: 10),
                Expanded(
                    child: _SkeletonLine(
                        width: double.infinity, height: 34, radius: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonDivider extends StatelessWidget {
  const _SkeletonDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFF1F5F9),
    );
  }
}

class _SkeletonLine extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _SkeletonLine({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  State<_SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<_SkeletonLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final highlight =
        isDark ? const Color(0xFF3B4A63) : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final color = Color.lerp(base, highlight, _controller.value);
        return Container(
          width: widget.width.isInfinite ? double.infinity : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
