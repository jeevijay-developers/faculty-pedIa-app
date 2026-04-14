import 'package:flutter/material.dart';

// Educator profile skeleton shown while profile data is loading.
class EducatorProfileSkeleton extends StatelessWidget {
  const EducatorProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            title: const _SkeletonLine(width: 140, height: 14, radius: 6),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: const [
                  _SkeletonHeaderCard(),
                  SizedBox(height: 14),
                  _SkeletonStatsRow(),
                  SizedBox(height: 14),
                  _SkeletonTabs(),
                  SizedBox(height: 14),
                  _SkeletonContentCard(),
                  SizedBox(height: 10),
                  _SkeletonContentCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonHeaderCard extends StatelessWidget {
  const _SkeletonHeaderCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: const [
          _SkeletonLine(width: 84, height: 84, radius: 42),
          SizedBox(height: 12),
          _SkeletonLine(width: 160, height: 14, radius: 6),
          SizedBox(height: 6),
          _SkeletonLine(width: 90, height: 10, radius: 6),
          SizedBox(height: 12),
          _SkeletonLine(width: double.infinity, height: 12, radius: 6),
          SizedBox(height: 6),
          _SkeletonLine(width: 220, height: 10, radius: 6),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _SkeletonLine(
                      width: double.infinity, height: 38, radius: 14)),
              SizedBox(width: 10),
              Expanded(
                  child: _SkeletonLine(
                      width: double.infinity, height: 38, radius: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonStatsRow extends StatelessWidget {
  const _SkeletonStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _SkeletonCard(height: 78)),
        SizedBox(width: 10),
        Expanded(child: _SkeletonCard(height: 78)),
        SizedBox(width: 10),
        Expanded(child: _SkeletonCard(height: 78)),
        SizedBox(width: 10),
        Expanded(child: _SkeletonCard(height: 78)),
      ],
    );
  }
}

class _SkeletonTabs extends StatelessWidget {
  const _SkeletonTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonLine(width: 90, height: 28, radius: 14),
        SizedBox(width: 10),
        _SkeletonLine(width: 90, height: 28, radius: 14),
        SizedBox(width: 10),
        _SkeletonLine(width: 90, height: 28, radius: 14),
      ],
    );
  }
}

class _SkeletonContentCard extends StatelessWidget {
  const _SkeletonContentCard();

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
      ),
      child: const Row(
        children: [
          _SkeletonLine(width: 64, height: 64, radius: 14),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SkeletonLine(width: double.infinity, height: 12, radius: 6),
                SizedBox(height: 6),
                _SkeletonLine(width: 160, height: 10, radius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: _SkeletonLine(width: 36, height: 36, radius: 10),
      ),
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
