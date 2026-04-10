import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

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

class TestResultScreen extends ConsumerWidget {
  final String resultId;
  final Map<String, dynamic>? resultData;

  const TestResultScreen({
    super.key,
    required this.resultId,
    this.resultData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final result = resultData ??
        {
          'title': 'Test Result',
          'score': 0,
          'totalMarks': 0,
          'correct': 0,
          'wrong': 0,
          'unattempted': 0,
          'percentage': 0.0,
          'accuracy': 0.0,
          'pace': '—',
        };

    final title = result['title']?.toString() ?? 'Test Result';
    final score = (result['score'] as num?)?.toInt() ?? 0;
    final totalMarks = (result['totalMarks'] as num?)?.toInt() ?? 0;
    final correct = (result['correct'] as num?)?.toInt() ?? 0;
    final wrong = (result['wrong'] as num?)?.toInt() ?? 0;
    final unattempted = (result['unattempted'] as num?)?.toInt() ?? 0;
    final percentage = (result['percentage'] as num?)?.toDouble() ?? 0.0;
    final accuracy = (result['accuracy'] as num?)?.toDouble() ?? 0.0;
    final pace = result['pace']?.toString() ?? '—';
    final perfLabel = _performanceLabel(percentage);
    final perfColor = _performanceColor(percentage);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            children: [
              // ── Top icon + submitted label ───────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                'TEST SUBMITTED',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: isDark ? kText2Dark : kText3Light,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: isDark ? kText1Dark : kText1Light,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_done_rounded,
                      size: 13, color: isDark ? kText2Dark : kText3Light),
                  const SizedBox(width: 5),
                  Text(
                    'Submission saved and synced',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? kText2Dark : kText3Light,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Hero score card ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                      right: -20,
                      top: -20,
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
                      children: [
                        Text(
                          'FINAL SCORE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // score + circular indicator row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -2,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 72,
                              height: 72,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: percentage / 100,
                                    strokeWidth: 5,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                  ),
                                  Center(
                                    child: Text(
                                      '${percentage.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'out of $totalMarks marks',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // hairline divider
                        Divider(
                            height: 1, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 14),
                        // performance badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            perfLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Accuracy + Pace ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.bolt_rounded,
                      label: 'ACCURACY',
                      value: '${accuracy.toStringAsFixed(0)}%',
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.speed_rounded,
                      label: 'PACE',
                      value: pace,
                      color: kPrimary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Correct / Incorrect / Skipped ────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.check_circle_rounded,
                      label: 'CORRECT',
                      value: '$correct',
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.cancel_rounded,
                      label: 'WRONG',
                      value: '$wrong',
                      color: const Color(0xFFEF4444),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.remove_circle_rounded,
                      label: 'SKIPPED',
                      value: '$unattempted',
                      color: kText3Light,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Segmented answer bar ─────────────────────────────────
              _buildAnswerBar(
                  correct: correct,
                  wrong: wrong,
                  skipped: unattempted,
                  isDark: isDark),

              const SizedBox(height: 16),

              // ── Improvement tip card ─────────────────────────────────
              _buildTipCard(percentage, isDark),

              const SizedBox(height: 20),

              // ── CTA: View Results ────────────────────────────────────
              GestureDetector(
                onTap: () => context.go('/results', extra: result),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'View Detailed Results',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Close / Go home ──────────────────────────────────────
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? kSurfaceDark : kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isDark ? Colors.white.withOpacity(0.06) : kDivLight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? kText2Dark : kText2Light,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Segmented answer bar ──────────────────────────────────────────────────
  Widget _buildAnswerBar({
    required int correct,
    required int wrong,
    required int skipped,
    required bool isDark,
  }) {
    final total = correct + wrong + skipped;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Answer Breakdown',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
          const SizedBox(height: 12),
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
                  if (skipped > 0)
                    Flexible(
                      flex: skipped,
                      child: Container(
                        color:
                            isDark ? Colors.white.withOpacity(0.1) : kDivLight,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _barLegend('Correct', correct, const Color(0xFF22C55E), isDark),
              _barLegend('Wrong', wrong, const Color(0xFFEF4444), isDark),
              _barLegend('Skipped', skipped, kText3Light, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barLegend(String label, int count, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: $count',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? kText2Dark : kText2Light,
          ),
        ),
      ],
    );
  }

  // ── Improvement tip card ──────────────────────────────────────────────────
  Widget _buildTipCard(double percentage, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.lightbulb_rounded, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Area for Improvement',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? kText1Dark : kText1Light,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getResultMessage(percentage),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: isDark ? kText2Dark : kText2Light,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _performanceLabel(double p) {
    if (p >= 90) return '🏆  Excellent';
    if (p >= 75) return '✅  Strong';
    if (p >= 60) return '👍  Good';
    if (p >= 40) return '📚  Needs Practice';
    return '⚠️  Needs Improvement';
  }

  Color _performanceColor(double p) {
    if (p >= 90) return const Color(0xFF16A34A);
    if (p >= 75) return kPrimary;
    if (p >= 60) return const Color(0xFF2563EB);
    if (p >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getResultMessage(double p) {
    if (p >= 90) return 'Excellent performance. Keep the momentum going!';
    if (p >= 75) return 'Strong result. A bit more practice goes a long way.';
    if (p >= 60) return 'Good effort. Focus on accuracy next time.';
    if (p >= 40) return 'Review the basics to build confidence.';
    return 'Start with core concepts to improve your score.';
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? kText2Dark : kText3Light,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
