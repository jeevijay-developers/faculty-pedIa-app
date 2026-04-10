import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/models/hamburger_model.dart';

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

class ResultsTabScreen extends ConsumerWidget {
  final Map<String, dynamic>? resultData;
  const ResultsTabScreen({super.key, this.resultData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = resultData ??
        {
          'title': 'Test Results',
          'score': 0,
          'totalMarks': 0,
          'correct': 0,
          'wrong': 0,
          'percentage': 0.0,
        };

    final title = result['title']?.toString() ?? 'Test Results';
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final totalMarks = (result['totalMarks'] as num?)?.toInt() ?? 0;
    final correct = (result['correct'] as num?)?.toInt() ?? 0;
    final wrong = (result['wrong'] as num?)?.toInt() ?? 0;
    final percentage = (result['percentage'] as num?)?.toDouble() ?? 0.0;
    final date = DateFormatter.formatDate(DateTime.now());

    final perfLabel = _performanceLabel(percentage);
    final perfColor = _performanceColor(percentage);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ──────────────────────────────────────────────────
          _buildSliverAppBar(context, isDark),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero score card ──────────────────────────────────
                  _buildHeroCard(
                    title: title,
                    score: score,
                    totalMarks: totalMarks,
                    percentage: percentage,
                    perfLabel: perfLabel,
                    perfColor: perfColor,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 20),

                  // ── Stats grid ───────────────────────────────────────
                  _sectionLabel('Overview', isDark),
                  const SizedBox(height: 12),
                  _buildStatsGrid(
                    percentage: percentage,
                    score: score,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // ── Correct / Wrong breakdown ─────────────────────────
                  _sectionLabel('Answer Breakdown', isDark),
                  const SizedBox(height: 12),
                  _buildBreakdownRow(
                    correct: correct,
                    wrong: wrong,
                    total: correct + wrong,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // ── Result detail card ────────────────────────────────
                  _sectionLabel('Test Detail', isDark),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    title: title,
                    score: score,
                    totalMarks: totalMarks,
                    correct: correct,
                    wrong: wrong,
                    date: date,
                    perfLabel: perfLabel,
                    perfColor: perfColor,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
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
                    'MY PERFORMANCE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Test Results',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your exam performance',
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

  // ── Hero score card ───────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required String title,
    required int score,
    required int totalMarks,
    required double percentage,
    required String perfLabel,
    required Color perfColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title + performance badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      perfLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // big score + percentage
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                          height: 1,
                        ),
                      ),
                      Text(
                        'out of $totalMarks',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // circular percentage indicator
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        Center(
                          child: Text(
                            '${percentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────
  Widget _buildStatsGrid({
    required double percentage,
    required int score,
    required bool isDark,
  }) {
    final stats = [
      _StatItem('ATTEMPTS', '1', Icons.repeat_rounded, 'Total submissions'),
      _StatItem('AVG %', '${percentage.toStringAsFixed(0)}%',
          Icons.percent_rounded, 'Average accuracy'),
      _StatItem('AVG SCORE', '$score', Icons.score_rounded, 'Per test'),
      _StatItem('BEST %', '${percentage.toStringAsFixed(0)}%',
          Icons.emoji_events_rounded, 'Top performance'),
    ];

    return Row(
      children: stats.map((s) {
        final isLast = s == stats.last;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: _StatCard(stat: s, isDark: isDark)),
              if (!isLast) const SizedBox(width: 10),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Breakdown row ─────────────────────────────────────────────────────────
  Widget _buildBreakdownRow({
    required int correct,
    required int wrong,
    required int total,
    required bool isDark,
  }) {
    final unanswered = (total - correct - wrong).clamp(0, total);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // progress bar
          if (total > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    Flexible(
                      flex: correct,
                      child: Container(color: const Color(0xFF22C55E)),
                    ),
                    Flexible(
                      flex: wrong,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                    if (unanswered > 0)
                      Flexible(
                        flex: unanswered,
                        child: Container(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : kDivLight,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // stats
          Row(
            children: [
              Expanded(
                child: _breakdownCell(
                  label: 'Correct',
                  value: '$correct',
                  color: const Color(0xFF22C55E),
                  bgColor: const Color(0xFFDCFCE7),
                  icon: Icons.check_circle_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _breakdownCell(
                  label: 'Wrong',
                  value: '$wrong',
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  icon: Icons.cancel_rounded,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _breakdownCell(
                  label: 'Total',
                  value: '$total',
                  color: kPrimary,
                  bgColor: kPrimaryBg,
                  icon: Icons.list_alt_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownCell({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.15) : bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? kText2Dark : kText3Light,
          ),
        ),
      ],
    );
  }

  // ── Detail card ───────────────────────────────────────────────────────────
  Widget _buildDetailCard({
    required String title,
    required int score,
    required int totalMarks,
    required int correct,
    required int wrong,
    required String date,
    required String perfLabel,
    required Color perfColor,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: kPrimaryBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: isDark ? kText1Dark : kText1Light,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Independent Test',
                        style: TextStyle(
                          fontSize: 11,
                          color: kText3Light,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: perfColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: perfColor.withOpacity(0.25)),
                  ),
                  child: Text(
                    perfLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: perfColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
          ),

          // ── Stats rows ───────────────────────────────────────────────
          _detailRow('Score', '$score / $totalMarks', isDark),
          _detailRow('Correct Answers', '$correct', isDark),
          _detailRow('Wrong Answers', '$wrong', isDark),
          _detailRow('Date', date, isDark, isLast: true),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark,
      {bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
          if (!isLast)
            Divider(
              height: 0,
              color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
            ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: isDark ? kText1Dark : kText1Light,
      ),
    );
  }

  String _performanceLabel(double p) {
    if (p >= 85) return 'Excellent';
    if (p >= 70) return 'Good';
    if (p >= 50) return 'Average';
    return 'Needs Work';
  }

  Color _performanceColor(double p) {
    if (p >= 85) return const Color(0xFF16A34A);
    if (p >= 70) return kPrimary;
    if (p >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────
class _StatItem {
  final String label, value, subtitle;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon, this.subtitle);
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(stat.icon, color: kPrimary, size: 15),
          ),
          const SizedBox(height: 8),
          Text(
            stat.label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: kText3Light,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: kPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.subtitle,
            style: TextStyle(
              fontSize: 9,
              color: isDark ? kText2Dark : kText3Light,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
