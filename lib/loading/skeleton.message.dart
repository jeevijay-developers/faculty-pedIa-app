import 'package:flutter/material.dart';
import '../shared/models/hamburger_model.dart';

// Messages skeleton shown while data is loading.
class MessageTabSkeleton extends StatelessWidget {
  const MessageTabSkeleton({super.key});

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
            expandedHeight: 148,
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
                        _SkeletonLine(width: 90, height: 10, radius: 6),
                        SizedBox(height: 6),
                        _SkeletonLine(width: 140, height: 22, radius: 10),
                        SizedBox(height: 6),
                        _SkeletonLine(width: 200, height: 12, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: const _SkeletonInfoBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: const _SkeletonLine(width: 140, height: 12, radius: 6),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                children: const [
                  _SkeletonMessageCard(),
                  SizedBox(height: 12),
                  _SkeletonMessageCard(),
                  SizedBox(height: 12),
                  _SkeletonMessageCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonInfoBanner extends StatelessWidget {
  const _SkeletonInfoBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        children: [
          _SkeletonLine(width: 42, height: 42, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: 150, height: 12, radius: 6),
                SizedBox(height: 6),
                _SkeletonLine(width: double.infinity, height: 10, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonMessageCard extends StatelessWidget {
  const _SkeletonMessageCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: const [
          Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _SkeletonLine(width: 36, height: 36, radius: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonLine(width: 120, height: 12, radius: 6),
                      SizedBox(height: 6),
                      _SkeletonLine(width: 80, height: 10, radius: 6),
                    ],
                  ),
                ),
                _SkeletonLine(width: 10, height: 10, radius: 5),
              ],
            ),
          ),
          _SkeletonDivider(),
          Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 6),
                _SkeletonLine(width: double.infinity, height: 10, radius: 6),
                SizedBox(height: 6),
                _SkeletonLine(width: 220, height: 10, radius: 6),
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
      indent: 14,
      endIndent: 14,
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
