import 'package:flutter/material.dart';
import '../shared/models/hamburger_model.dart';

// Dashboard skeleton shown while data is loading.
class StudentDashboardSkeleton extends StatelessWidget {
  const StudentDashboardSkeleton({super.key});

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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
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
                        _SkeletonLine(width: 180, height: 22, radius: 10),
                        SizedBox(height: 6),
                        _SkeletonLine(width: 160, height: 12, radius: 6),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(child: _SkeletonCard(height: 86)),
                      SizedBox(width: 10),
                      Expanded(child: _SkeletonCard(height: 86)),
                      SizedBox(width: 10),
                      Expanded(child: _SkeletonCard(height: 86)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _SkeletonLine(width: 120, height: 16, radius: 6),
                  const SizedBox(height: 12),
                  const _SkeletonCard(height: 92),
                  const SizedBox(height: 24),
                  const _SkeletonSectionHeader(),
                  const SizedBox(height: 12),
                  const _SkeletonCard(height: 150),
                  const SizedBox(height: 24),
                  const _SkeletonSectionHeader(),
                  const SizedBox(height: 12),
                  const _SkeletonCard(height: 78),
                  const SizedBox(height: 10),
                  const _SkeletonCard(height: 78),
                  const SizedBox(height: 24),
                  const _SkeletonCard(height: 104),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonSectionHeader extends StatelessWidget {
  const _SkeletonSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _SkeletonLine(width: 140, height: 16, radius: 6),
        _SkeletonLine(width: 64, height: 18, radius: 10),
      ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: _SkeletonBlockLayout(),
      ),
    );
  }
}

class _SkeletonBlockLayout extends StatelessWidget {
  const _SkeletonBlockLayout();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _SkeletonLine(width: 44, height: 44, radius: 12),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonLine(width: double.infinity, height: 12, radius: 6),
              SizedBox(height: 8),
              _SkeletonLine(width: 120, height: 10, radius: 6),
            ],
          ),
        ),
      ],
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
