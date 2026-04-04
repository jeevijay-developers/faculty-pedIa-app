import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';

class HamburgerDrawer extends ConsumerWidget {
  const HamburgerDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _buildDrawerItem(
              context,
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              onTap: () => context.go('/dashboard'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.menu_book_outlined,
              title: 'My Courses',
              onTap: () => context.push('/courses'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.assignment_outlined,
              title: 'Test Series',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.videocam_outlined,
              title: 'Live Classes',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.event_outlined,
              title: 'Webinars',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.task_alt_outlined,
              title: 'Results',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.chat_bubble_outline,
              title: 'Messages',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.people_outline,
              title: 'Following',
              onTap: () => context.push('/educators'),
            ),
            const Divider(height: 24),
            _buildDrawerItem(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () => context.push('/edit-profile'),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              titleColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: () async {
                final confirm = await _showLogoutDialog(context);
                if (confirm && context.mounted) {
                  await ref.read(authStateProvider.notifier).logout();
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.grey700),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Future<bool> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
