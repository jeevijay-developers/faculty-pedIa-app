import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/user_widgets.dart';

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

class HamburgerDrawer extends ConsumerWidget {
  const HamburgerDrawer({super.key});

  // ── Menu sections ────────────────────────────────────────────────────────────
  static const _mainItems = [
    _DrawerItem(Icons.home_rounded, 'Home', '/home', false),
    _DrawerItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard', false),
    _DrawerItem(
        Icons.menu_book_rounded, 'My Courses', '/student-courses', false),
    _DrawerItem(Icons.assignment_rounded, 'Test Series',
        '/dashboard/test-series', false),
    _DrawerItem(Icons.live_tv_rounded, 'Live Classes', null, false),
    _DrawerItem(Icons.videocam_rounded, 'Webinars', null, false),
    _DrawerItem(Icons.task_alt_rounded, 'Results', null, false),
    _DrawerItem(Icons.chat_bubble_rounded, 'Messages', null, false),
    _DrawerItem(Icons.people_alt_rounded, 'Following', '/educators', false),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final location = GoRouterState.of(context).uri.path;
    final mainItems = _buildMainItems(location);

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            _buildHeader(context, authState, isDark),

            // ── Menu ───────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _sectionLabel('Main Menu', isDark),
                  const SizedBox(height: 4),
                  ...mainItems.map(
                    (item) => _ModernDrawerTile(
                      item: item,
                      isDark: isDark,
                      onTap: () => _navigate(context, item),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _divider(isDark),
                  const SizedBox(height: 8),

                  // Logout
                  _LogoutTile(isDark: isDark, ref: ref),
                ],
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            _buildFooter(isDark),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthState authState, bool isDark) {
    final name = authState.user?.name ?? 'Student';
    final email = authState.user?.email ?? '';
    final imageUrl = authState.user?.imageUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          // decorative circle
          Positioned(
            right: -16,
            top: -16,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // avatar
              UserAvatar(
                imageUrl: imageUrl,
                name: name,
                size: 62,
                showBorder: true,
                borderColor: Colors.white.withOpacity(0.4),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // View profile pill
            ],
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Divider(height: 1, color: Colors.grey.withOpacity(0.12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Faculty Pedia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'v1.0.0',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
        color: Colors.grey.withOpacity(0.12),
      );

  void _navigate(BuildContext context, _DrawerItem item) {
    Navigator.pop(context);
    if (item.route != null) {
      context.go(item.route!);
    }
  }

  List<_DrawerItem> _buildMainItems(String location) {
    final normalized = location.split('?').first;
    final matches = _mainItems.where((item) {
      final route = item.route;
      if (route == null || route.isEmpty) return false;
      return normalized == route || normalized.startsWith('$route/');
    }).toList();

    String? activeRoute;
    if (matches.isNotEmpty) {
      final bestMatch = matches.reduce((a, b) {
        final aLen = a.route?.length ?? 0;
        final bLen = b.route?.length ?? 0;
        return aLen >= bLen ? a : b;
      });
      activeRoute = bestMatch.route;
    }

    return _mainItems.map((item) {
      if (item.route == null || item.route!.isEmpty) return item;
      return _DrawerItem(
        item.icon,
        item.title,
        item.route,
        item.route == activeRoute,
      );
    }).toList();
  }
}

// ── Modern Drawer Tile ─────────────────────────────────────────────────────────
class _ModernDrawerTile extends StatefulWidget {
  final _DrawerItem item;
  final bool isDark;
  final VoidCallback onTap;
  const _ModernDrawerTile(
      {required this.item, required this.isDark, required this.onTap});

  @override
  State<_ModernDrawerTile> createState() => _ModernDrawerTileState();
}

class _ModernDrawerTileState extends State<_ModernDrawerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.item.isActive;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) {
        setState(() => _hovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? kPrimary
              : _hovered
                  ? (isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: active
                    ? Colors.white.withOpacity(0.2)
                    : (isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                widget.item.icon,
                size: 19,
                color: active
                    ? Colors.white
                    : (isDark ? Colors.white60 : kPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? Colors.white
                      : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                  letterSpacing: -0.1,
                ),
              ),
            ),
            if (active)
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ── Logout Tile ────────────────────────────────────────────────────────────────
class _LogoutTile extends StatefulWidget {
  final bool isDark;
  final WidgetRef ref;
  const _LogoutTile({required this.isDark, required this.ref});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) async {
        setState(() => _hovered = false);
        final confirm = await _showLogoutDialog(context);
        if (confirm && context.mounted) {
          await widget.ref.read(authStateProvider.notifier).logout();
          context.go('/login');
        }
      },
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFEF2F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 19,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Logout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 30,
                  ),
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
                    // Cancel
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
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
                    // Logout
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
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
                                color: Color(0xFFDC2626).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
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
        );
      },
    );
    return result ?? false;
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────
class _DrawerItem {
  final IconData icon;
  final String title;
  final String? route;
  final bool isActive;
  const _DrawerItem(this.icon, this.title, this.route, this.isActive);
}
