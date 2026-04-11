import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

// ── Blue-600 palette ──────────────────────────────────────────────────────────
const kPrimary = Color(0xFF2563EB); // blue-600
const kPrimaryLight = Color(0xFF3B82F6); // blue-500
const kPrimaryDark = Color(0xFF1D4ED8); // blue-700
const kPrimaryBg = Color(0xFFEFF6FF); // blue-50
const kPrimaryMid = Color(0xFFBFDBFE); // blue-200

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bannerIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadAsync = ref.watch(unreadCountProvider);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async {
          ref.invalidate(unreadCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark, unreadAsync, authState),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildBanner(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader(context, 'Exam Preparation',
                      onSeeAll: () => context.go('/exams')),
                  const SizedBox(height: 14),
                  _buildExamCategories(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader(context, 'Explore Features'),
                  const SizedBox(height: 8),
                  _buildFeaturesGrid(context, isDark),
                  const SizedBox(height: 28),
                  _buildQuickActions(context),
                  const SizedBox(height: 28),
                  _buildStatsSection(context, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ────────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    bool isDark,
    AsyncValue<int> unreadAsync,
    AuthState authState,
  ) {
    final imageUrl = authState.user?.imageUrl;
    return SliverAppBar(
      floating: true,
      snap: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: kPrimaryBg,
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipOval(
                    child: AppNetworkImage(
                      imageUrl: imageUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    (authState.user?.initials ?? 'S').toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                authState.user?.displayName ?? 'Student',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        _appBarIcon(
          Icons.notifications_outlined,
          badge: unreadAsync.maybeWhen(
            data: (count) => count > 0,
            orElse: () => false,
          ),
          onTap: () => context.push('/notifications'),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(
          height: 0.5,
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
    );
  }

  Widget _appBarIcon(IconData icon,
      {bool badge = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: kPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          if (badge)
            Positioned(
              top: 8,
              right: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Banner Carousel ──────────────────────────────────────────────────────────
  Widget _buildBanner(BuildContext context) {
    final banners = [
      _BannerData(
        title: 'Meet Your Favorite\nEducators',
        subtitle: 'Join live classes with India\'s top faculty',
        gradient: [kPrimary, kPrimaryDark],
        icon: Icons.people_alt_rounded,
        route: '/educators',
      ),
      _BannerData(
        title: 'Practice with\nTest Series',
        subtitle: 'Solve tests. Track your performance.',
        gradient: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
        icon: Icons.cast_for_education_rounded,
        route: '/test-series',
      ),
      _BannerData(
        title: 'Crack Your Dream\nExam',
        subtitle: 'Access premium Courses & Study Materials',
        gradient: [const Color(0xFF059669), const Color(0xFF047857)],
        icon: Icons.emoji_events_rounded,
        route: '/exams',
      ),
    ];

    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 184,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enlargeCenterPage: false,
            viewportFraction: 0.92,
            onPageChanged: (i, _) => setState(() => _bannerIndex = i),
          ),
          items: banners.map((b) => _bannerCard(context, b)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _bannerIndex == i ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _bannerIndex == i ? kPrimary : kPrimaryMid,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bannerCard(BuildContext context, _BannerData b) {
    return GestureDetector(
      onTap: b.route == null ? null : () => context.go(b.route!),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: b.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Explore Now',
                            style: TextStyle(
                              color: b.gradient.first,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(b.icon, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Header ───────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Exam Categories ──────────────────────────────────────────────────────────
  Widget _buildExamCategories(BuildContext context) {
    final exams = [
      _ExamData(
          'IIT-JEE',
          Icons.science_rounded,
          [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
          '/exam-content/iit-jee'),
      _ExamData(
          'NEET',
          Icons.medical_services_rounded,
          [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
          '/exam-content/neet'),
      _ExamData(
          'CBSE',
          Icons.school_rounded,
          [const Color(0xFF059669), const Color(0xFF047857)],
          '/exam-content/cbse'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: exams.map((e) {
          final isLast = e == exams.last;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(e.route),
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: e.gradient.first.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: e.gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(e.icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            e.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: e.gradient.first,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast) const SizedBox(width: 12),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Features Grid ────────────────────────────────────────────────────────────
  Widget _buildFeaturesGrid(BuildContext context, bool isDark) {
    final features = [
      _FeatureData('Courses', '240+ Modules', Icons.play_circle_rounded,
          kPrimary, '/courses'),
      _FeatureData('Test Series', 'Mock Exams', Icons.assignment_rounded,
          const Color(0xFF7C3AED), '/test-series'),
      _FeatureData('Webinars', 'Live Sessions', Icons.videocam_rounded,
          const Color(0xFF059669), '/webinars'),
      _FeatureData(
          'Educators',
          'Expert Mentors',
          Icons.supervisor_account_rounded,
          const Color(0xFFD97706),
          '/educators'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        itemCount: features.length,
        itemBuilder: (context, i) {
          final f = features[i];
          return GestureDetector(
            onTap: () => context.push(f.route),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B1220) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF94A3B8).withOpacity(0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: f.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.icon, color: f.color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    f.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    f.subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Quick Actions ────────────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.play_circle_fill_rounded,
                  title: 'Start Learning',
                  subtitle: 'Browse Courses',
                  gradient: [kPrimary, kPrimaryDark],
                  onTap: () => context.push('/courses'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.assignment_turned_in_rounded,
                  title: 'Take a Test',
                  subtitle: 'Practice Now',
                  gradient: [const Color(0xFF7C3AED), const Color(0xFF5B21B6)],
                  onTap: () => context.push('/test-series'),
                ),
              ),
            ],
          ),

          // Wide single card
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool wide = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.30),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.7), size: 14),
          ],
        ),
      ),
    );
  }

  // ── Stats Section ────────────────────────────────────────────────────────────
  Widget _buildStatsSection(BuildContext context, bool isDark) {
    final stats = [
      _StatData('500+', 'Educators', Icons.people_rounded),
      _StatData('1K+', 'Courses', Icons.play_circle_rounded),
      _StatData('10K+', 'Students', Icons.school_rounded),
      _StatData('5K+', 'Tests', Icons.assignment_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Trusted Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Trusted by thousands\nacross India',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stats
                  .map(
                    (s) => Column(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(s.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data Models ───────────────────────────────────────────────────────────────
class _BannerData {
  final String title, subtitle;
  final List<Color> gradient;
  final IconData icon;
  final String? route;
  const _BannerData(
      {required this.title,
      required this.subtitle,
      required this.gradient,
      required this.icon,
      this.route});
}

class _ExamData {
  final String name, route;
  final IconData icon;
  final List<Color> gradient;
  const _ExamData(this.name, this.icon, this.gradient, this.route);
}

class _FeatureData {
  final String name, subtitle, route;
  final IconData icon;
  final Color color;
  const _FeatureData(
      this.name, this.subtitle, this.icon, this.color, this.route);
}

class _StatData {
  final String value, label;
  final IconData icon;
  const _StatData(this.value, this.label, this.icon);
}
