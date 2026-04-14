import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

const kSurface = Colors.white;
const kSurfaceDark = Color(0xFF1E293B);
const kBgLight = Color(0xFFF8FAFC);
const kBgDark = Color(0xFF0F172A);
const kText2Light = Color(0xFF64748B);
const kText3Light = Color(0xFF94A3B8);
const kText2Dark = Color(0xFF94A3B8);
const kDivLight = Color(0xFFF1F5F9);

// ── Nav items ──────────────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

const _navItems = [
  _NavItem(
    label: 'Home',
    icon: Icons.cottage_outlined,
    activeIcon: Icons.cottage_rounded,
    route: '/home',
  ),
  _NavItem(
    label: 'Exams',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
    route: '/exams',
  ),
  _NavItem(
    label: 'Educators',
    icon: Icons.supervisor_account_outlined,
    activeIcon: Icons.supervisor_account_rounded,
    route: '/educators',
  ),
  _NavItem(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    route: '/profile',
  ),
];

// ── Shell ──────────────────────────────────────────────────────────────────────
class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  // one scale controller per tab for press animation
  late final List<AnimationController> _scaleCtrl;
  late final List<Animation<double>> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = List.generate(
      _navItems.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 120)),
    );
    _scaleAnim = _scaleCtrl.map((c) {
      return Tween<double>(begin: 1.0, end: 0.85)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _scaleCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  int _selectedIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/home')) return 0;
    if (path.startsWith('/exams')) return 1;
    if (path.startsWith('/educators')) return 2;
    if (path.startsWith('/dashboard')) return 3;
    if (path.startsWith('/student-courses')) return 3;
    if (path.startsWith('/messages')) return 3;
    if (path.startsWith('/following')) return 3;
    if (path.startsWith('/results')) return 3;
    if (path.startsWith('/profile')) return 3;
    if (path.startsWith('/help')) return 3;
    if (path.startsWith('/privacy')) return 3;
    return 0;
  }

  void _onTap(int index, BuildContext context) {
    // haptic + scale animation
    HapticFeedback.lightImpact();
    _scaleCtrl[index].forward().then((_) => _scaleCtrl[index].reverse());
    context.go(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _buildNavBar(isDark, selected, context),
    );
  }

  // ── Nav bar ────────────────────────────────────────────────────────────────
  Widget _buildNavBar(bool isDark, int selected, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final isActive = selected == i;

              return Expanded(
                child: AnimatedBuilder(
                  animation: _scaleAnim[i],
                  builder: (_, child) => Transform.scale(
                    scale: _scaleAnim[i].value,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: () => _onTap(i, context),
                    behavior: HitTestBehavior.opaque,
                    child: _NavTile(
                      item: item,
                      isActive: isActive,
                      isDark: isDark,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── Nav tile ───────────────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool isDark;

  const _NavTile({
    required this.item,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // icon pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isActive ? kPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: kPrimary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              isActive ? item.activeIcon : item.icon,
              size: 22,
              color:
                  isActive ? Colors.white : (isDark ? kText2Dark : kText3Light),
            ),
          ),

          const SizedBox(height: 4),

          // label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              color: isActive ? kPrimary : (isDark ? kText2Dark : kText3Light),
              letterSpacing: isActive ? -0.1 : 0,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
