import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../shared/models/educator_model.dart';
import '../../../shared/models/hamburger_model.dart';
import '../../../shared/models/student_model.dart';
import '../../../shared/widgets/user_widgets.dart';
import '../../auth/providers/auth_provider.dart';

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Menu item data model ───────────────────────────────────────────────────────
class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool showBadge;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
    required this.onTap,
    this.showBadge = false,
  });
}

class ProfileStats {
  final int totalCourses;
  final int testSeriesCount;
  final int followingCount;

  const ProfileStats({
    required this.totalCourses,
    required this.testSeriesCount,
    required this.followingCount,
  });

  const ProfileStats.empty()
      : totalCourses = 0,
        testSeriesCount = 0,
        followingCount = 0;
}

final profileStatsProvider =
    FutureProvider.autoDispose<ProfileStats>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ref.watch(apiServiceProvider);
  final responses = await Future.wait([
    api.get('/api/students/$studentId/statistics'),
    api.get('/api/students/$studentId'),
  ]);

  final statsPayload = responses[0].data is Map<String, dynamic>
      ? responses[0].data as Map<String, dynamic>
      : <String, dynamic>{};
  final statsData = statsPayload['data'] is Map<String, dynamic>
      ? statsPayload['data'] as Map<String, dynamic>
      : statsPayload;

  final totalCourses = (statsData['totalCourses'] as num?)?.toInt() ?? 0;
  final followingCount =
      (statsData['totalEducatorsFollowing'] as num?)?.toInt() ?? 0;

  final detailsPayload = responses[1].data is Map<String, dynamic>
      ? responses[1].data as Map<String, dynamic>
      : <String, dynamic>{};
  final detailsData = detailsPayload['data'] is Map<String, dynamic>
      ? detailsPayload['data'] as Map<String, dynamic>
      : detailsPayload;
  final rawTestSeries = detailsData['testSeries'];
  final testSeriesCount = rawTestSeries is List ? rawTestSeries.length : 0;

  return ProfileStats(
    totalCourses: totalCourses,
    testSeriesCount: testSeriesCount,
    followingCount: followingCount,
  );
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  late AnimationController _avatarCtrl;
  late Animation<double> _avatarScale;

  @override
  void initState() {
    super.initState();
    _avatarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _avatarScale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _avatarCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _avatarCtrl.dispose();
    super.dispose();
  }

  // ── Image upload ────────────────────────────────────────────────────────────
  Future<void> _changeProfileImage(BuildContext context) async {
    if (_isUploading) return;

    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user == null) {
      AppSnackbar.error(context, 'Please login to update your profile.');
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final api = ref.read(apiServiceProvider);

      if (authState.isEducator) {
        final formData = FormData.fromMap({
          'image':
              await MultipartFile.fromFile(picked.path, filename: picked.name),
        });
        final response = await api.uploadFile(
          '/api/educator-update/update-image/${user.id}',
          formData: formData,
        );
        final data = response.data;
        final educatorJson = data is Map<String, dynamic>
            ? (data['educator'] as Map<String, dynamic>?) ??
                (data['data'] is Map<String, dynamic>
                    ? data['data']['educator'] as Map<String, dynamic>?
                    : null)
            : null;
        if (educatorJson == null) throw Exception('Unable to parse educator');
        final updated = Educator.fromJson(educatorJson);
        await ref.read(authStateProvider.notifier).updateUser(updated);
      } else {
        final uploadForm = FormData.fromMap({
          'image':
              await MultipartFile.fromFile(picked.path, filename: picked.name),
        });
        final uploadResponse =
            await api.uploadFile('/api/upload/image', formData: uploadForm);
        final uploadData = uploadResponse.data;
        final imageUrl = uploadData is Map<String, dynamic>
            ? uploadData['imageUrl'] as String?
            : null;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Image upload failed');
        }
        final updateResponse = await api.put(
          '/api/students/${user.id}',
          data: {'image': imageUrl},
        );
        final updateData = updateResponse.data;
        final studentJson = updateData is Map<String, dynamic>
            ? (updateData['data'] as Map<String, dynamic>?) ??
                (updateData['student'] as Map<String, dynamic>?)
            : null;
        if (studentJson == null) throw Exception('Unable to parse student');
        final updated = Student.fromJson(studentJson);
        await ref.read(authStateProvider.notifier).updateUser(updated);
      }

      if (mounted) AppSnackbar.success(context, 'Profile image updated.');
    } catch (_) {
      if (mounted)
        AppSnackbar.error(context, 'Failed to update profile image.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statsAsync = ref.watch(profileStatsProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: Text('Please login')),
      );
    }

    final initials = user.displayName.trim().isNotEmpty
        ? user.displayName
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0])
            .join()
            .toUpperCase()
        : 'U';

    final menuItems = _buildMenuItems(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      drawer: const HamburgerDrawer(),
      body: CustomScrollView(
        slivers: [
          // ── Sliver AppBar ────────────────────────────────────────────────
          _buildSliverAppBar(context, isDark),

          // ── Profile hero card ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildProfileHero(context, user, initials, isDark),
          ),

          // ── Stats strip ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: statsAsync.when(
              loading: () =>
                  _buildStatsStrip(isDark, const ProfileStats.empty()),
              error: (_, __) =>
                  _buildStatsStrip(isDark, const ProfileStats.empty()),
              data: (stats) => _buildStatsStrip(isDark, stats),
            ),
          ),

          // ── Section label ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _sectionLabel('Quick Access', isDark),
          ),

          // ── Menu items ───────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ModernMenuItem(item: menuItems[i], isDark: isDark),
                childCount: menuItems.length,
              ),
            ),
          ),

          // ── Logout button ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildLogoutButton(context, isDark),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : kPrimaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_rounded, color: kPrimary, size: 20),
            ),
          ),
        ),
      ),
      title: Text(
        'My Profile',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      actions: [
        _appBarIconBtn(Icons.notifications_outlined, isDark,
            () => context.push('/notifications')),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: Colors.grey.withOpacity(0.12)),
      ),
    );
  }

  Widget _appBarIconBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : kPrimaryBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kPrimary, size: 18),
      ),
    );
  }

  // ── Profile Hero ─────────────────────────────────────────────────────────
  Widget _buildProfileHero(
    BuildContext context,
    dynamic user,
    String initials,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circles
          Positioned(right: -20, top: -20, child: _frostedCircle(110)),
          Positioned(left: -16, bottom: -30, child: _frostedCircle(90)),
          Positioned(right: 40, bottom: 10, child: _frostedCircle(50)),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                // avatar + upload
                GestureDetector(
                  onTapDown: (_) => _avatarCtrl.forward(),
                  onTapUp: (_) {
                    _avatarCtrl.reverse();
                    _changeProfileImage(context);
                  },
                  onTapCancel: () => _avatarCtrl.reverse(),
                  child: AnimatedBuilder(
                    animation: _avatarScale,
                    builder: (_, child) => Transform.scale(
                        scale: _avatarScale.value, child: child),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        // avatar ring
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                          child: UserAvatar(
                            imageUrl: user.imageUrl,
                            name: user.displayName,
                            size: 90,
                            showBorder: false,
                          ),
                        ),
                        // edit badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _isUploading
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: kPrimary.withOpacity(0.2), width: 1.5),
                          ),
                          child: _isUploading
                              ? const Padding(
                                  padding: EdgeInsets.all(7),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(kPrimary),
                                  ),
                                )
                              : const Icon(Icons.camera_alt_rounded,
                                  color: kPrimary, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // name
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // email
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // role pill + edit profile button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // role pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            'Student',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // edit profile button
                    GestureDetector(
                      onTap: () => _changeProfileImage(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, color: kPrimary, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              'Edit Image',
                              style: TextStyle(
                                color: kPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Strip ───────────────────────────────────────────────────────────
  Widget _buildStatsStrip(bool isDark, ProfileStats stats) {
    final items = [
      _StatData('${stats.totalCourses}', 'Courses', Icons.play_circle_rounded,
          kPrimary),
      _StatData('${stats.testSeriesCount}', 'Test Series',
          Icons.assignment_rounded, const Color(0xFF7C3AED)),
      _StatData('${stats.followingCount}', 'Following',
          Icons.people_alt_rounded, const Color(0xFF059669)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: items.map((s) {
          final isLast = s == items.last;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _StatCard(stat: s, isDark: isDark)),
                if (!isLast) const SizedBox(width: 10),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  // ── Menu items ────────────────────────────────────────────────────────────
  List<_MenuItem> _buildMenuItems(BuildContext context) => [
        _MenuItem(
          icon: Icons.play_circle_rounded,
          title: 'My Courses',
          subtitle: 'Continue learning',
          color: kPrimary,
          onTap: () => context.push('/student-courses'),
        ),
        _MenuItem(
          icon: Icons.assignment_rounded,
          title: 'My Test Results',
          subtitle: 'View scores & analysis',
          color: const Color(0xFF7C3AED),
          onTap: () => context.push('/results'),
        ),
        _MenuItem(
          icon: Icons.people_alt_rounded,
          title: 'Following Educators',
          subtitle: 'Manage your educators',
          color: const Color(0xFF059669),
          onTap: () => context.push('/following'),
        ),
        _MenuItem(
          icon: Icons.notifications_rounded,
          title: 'Notifications',
          subtitle: 'Alerts & updates',
          color: const Color(0xFFD97706),
          onTap: () => context.push('/notifications'),
          showBadge: true,
        ),
        _MenuItem(
          icon: Icons.help_rounded,
          title: 'Help & Support',
          subtitle: 'FAQs and contact us',
          color: const Color(0xFF0891B2),
          onTap: () => context.push('/help'),
        ),
        _MenuItem(
          icon: Icons.privacy_tip_rounded,
          title: 'Privacy Policy',
          subtitle: 'Terms and policies',
          color: const Color(0xFF64748B),
          onTap: () => context.push('/privacy'),
        ),
      ];

  // ── Logout button ─────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final confirm = await _showLogoutDialog(context, isDark);
            if (!confirm || !context.mounted) return;
            await ref.read(authStateProvider.notifier).logout();
            if (!context.mounted) return;
            context.go('/login');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                SizedBox(width: 10),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────
  Future<bool> _showLogoutDialog(BuildContext context, bool isDark) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFDC2626), size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to\nlogout from Faculty Pedia?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.of(context, rootNavigator: true).pop(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFDC2626),
                              Color(0xFFB91C1C),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFDC2626).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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
    );
    return result ?? false;
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

// ── Stat data model ────────────────────────────────────────────────────────────
class _StatData {
  final String value, label;
  final IconData icon;
  final Color color;
  const _StatData(this.value, this.label, this.icon, this.color);
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatData stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: stat.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Modern Menu Item ───────────────────────────────────────────────────────────
class _ModernMenuItem extends StatefulWidget {
  final _MenuItem item;
  final bool isDark;
  const _ModernMenuItem({required this.item, required this.isDark});

  @override
  State<_ModernMenuItem> createState() => _ModernMenuItemState();
}

class _ModernMenuItemState extends State<_ModernMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        item.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed
              ? item.color.withOpacity(0.06)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(isDark ? 0.1 : 0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // icon tile
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 14),
            // text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // badge + arrow
            if (item.showBadge)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: item.color),
            ),
          ],
        ),
      ),
    );
  }
}
