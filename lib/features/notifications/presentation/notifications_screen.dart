import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/notification_provider.dart';

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Notification type config ───────────────────────────────────────────────────
class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig(this.icon, this.color, this.label);
}

_TypeConfig _getTypeConfig(String type) {
  switch (type) {
    case 'course':
      return const _TypeConfig(
          Icons.play_circle_rounded, Color(0xFF2563EB), 'Course');
    case 'webinar':
      return const _TypeConfig(
          Icons.videocam_rounded, Color(0xFF059669), 'Webinar');
    case 'post':
      return const _TypeConfig(
          Icons.article_rounded, Color(0xFFF97316), 'Post');
    case 'test_series':
      return const _TypeConfig(
          Icons.assignment_rounded, Color(0xFF7C3AED), 'Test');
    case 'live_class':
      return const _TypeConfig(
          Icons.live_tv_rounded, Color(0xFFDC2626), 'Live');
    default:
      return const _TypeConfig(
          Icons.notifications_rounded, Color(0xFF2563EB), 'General');
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All';

  final _filters = [
    'All',
    'Course',
    'Live',
    'Webinar',
    'Test',
    'Post',
  ];

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadAsync = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(unreadCountProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── App Bar ───────────────────────────────────────────────────
            _buildSliverAppBar(context, unreadAsync, isDark),

            // ── Filter chips ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _buildFilterBar(isDark),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: notificationsAsync.when(
                loading: () => _loadingWidget(isDark),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(unreadCountProvider);
                    },
                  ),
                ),
                data: (notifications) {
                  final filtered = _applyFilter(notifications);

                  if (notifications.isEmpty) {
                    return _emptyWidget(isDark);
                  }
                  if (filtered.isEmpty) {
                    return _noFilterResults(isDark);
                  }

                  // Group by Today / Yesterday / Earlier
                  final groups = _groupNotifications(filtered);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: groups.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GroupLabel(label: entry.key, isDark: isDark),
                            const SizedBox(height: 8),
                            ...entry.value.map(
                              (n) => _NotificationTile(
                                notification: n,
                                isDark: isDark,
                                onTap: () => _handleTap(context, ref, n),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
    BuildContext context,
    AsyncValue<int> unreadAsync,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      actions: [
        unreadAsync.when(
          data: (count) => count > 0
              ? Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _markAllAsRead(ref),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
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
              right: -24,
              top: -24,
              child: _frostedCircle(120),
            ),
            Positioned(
              left: -16,
              bottom: -30,
              child: _frostedCircle(90),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // unread badge pill
                  unreadAsync.when(
                    data: (count) => count > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count unread',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'All caught up!',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
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

  // ── Filter Bar ────────────────────────────────────────────────────────────
  Widget _buildFilterBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final f = _filters[i];
            final active = _selectedFilter == f;
            return GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? kPrimary
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? kPrimary
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: kPrimary.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? Colors.white
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Filter logic ──────────────────────────────────────────────────────────
  List<AppNotification> _applyFilter(List<AppNotification> list) {
    if (_selectedFilter == 'All') return list;
    final key = _selectedFilter.toLowerCase().replaceAll(' ', '_');
    return list.where((n) => n.type.toLowerCase().contains(key)).toList();
  }

  // ── Group by date ─────────────────────────────────────────────────────────
  Map<String, List<AppNotification>> _groupNotifications(
      List<AppNotification> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AppNotification>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final n in list) {
      if (n.createdAt == null) {
        groups['Earlier']!.add(n);
        continue;
      }
      final d =
          DateTime(n.createdAt!.year, n.createdAt!.month, n.createdAt!.day);
      if (d == today) {
        groups['Today']!.add(n);
      } else if (d == yesterday) {
        groups['Yesterday']!.add(n);
      } else {
        groups['Earlier']!.add(n);
      }
    }

    // remove empty groups
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  // ── Handlers ──────────────────────────────────────────────────────────────
  Future<void> _handleTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    if (!notification.isRead) {
      await _markAsRead(ref, notification.id);
    }
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);

    final route = _resolveNotificationRoute(notification);
    if (route != null && route.isNotEmpty && context.mounted) {
      _openRoute(context, route);
    }
  }

  void _openRoute(BuildContext context, String route) {
    final useGo = route.startsWith('/dashboard') ||
        route == '/home' ||
        route == '/student-courses' ||
        route == '/courses' ||
        route == '/posts' ||
        route == '/test-series' ||
        route == '/webinars';
    if (useGo) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  String? _resolveNotificationRoute(AppNotification notification) {
    final meta = notification.metadata;
    final resourceRoute = meta?.resourceRoute;
    final link = meta?.link;
    final type = (meta?.resourceType ?? notification.type).toLowerCase();
    final routeId =
        _extractIdFromRoute(resourceRoute) ?? _extractIdFromRoute(link);
    final id = meta?.resourceId ?? routeId;

    if (resourceRoute != null && resourceRoute.isNotEmpty) {
      final normalized = _normalizeRoute(resourceRoute, type, id);
      if (normalized != null) return normalized;
    }

    if (link != null && link.isNotEmpty) {
      final normalized = _normalizeRoute(link, type, id);
      if (normalized != null) return normalized;
    }

    switch (type) {
      case 'course':
        return id != null && id.isNotEmpty ? '/course/$id' : '/courses';
      case 'test_series':
      case 'testseries':
      case 'test':
        return id != null && id.isNotEmpty
            ? '/test-series/$id'
            : '/test-series';
      case 'webinar':
        return id != null && id.isNotEmpty ? '/webinar/$id' : '/webinars';
      case 'live_class':
      case 'live':
        return id != null && id.isNotEmpty
            ? '/webinar/$id'
            : '/dashboard/webinars';
      case 'post':
        return '/posts';
      default:
        return null;
    }
  }

  String? _normalizeRoute(String raw, String type, String? id) {
    final uri = Uri.tryParse(raw);
    final path = uri?.path ?? raw;
    if (!path.startsWith('/')) return null;

    if (path.startsWith('/student-test-series/')) {
      final fallbackId = id ?? _extractIdFromRoute(path);
      return fallbackId != null && fallbackId.isNotEmpty
          ? '/test-series/$fallbackId'
          : '/test-series';
    }

    if (path.startsWith('/test-series') && id != null && id.isNotEmpty) {
      return '/test-series/$id';
    }
    if (path.startsWith('/course') && id != null && id.isNotEmpty) {
      return '/course/$id';
    }
    if (path.startsWith('/webinar') && id != null && id.isNotEmpty) {
      return '/webinar/$id';
    }
    if (path.startsWith('/posts')) return '/posts';

    if (type == 'test_series' || type == 'testseries' || type == 'test') {
      return id != null && id.isNotEmpty ? '/test-series/$id' : '/test-series';
    }
    if (type == 'course') {
      return id != null && id.isNotEmpty ? '/course/$id' : '/courses';
    }
    if (type == 'webinar' || type == 'live' || type == 'live_class') {
      return id != null && id.isNotEmpty ? '/webinar/$id' : '/webinars';
    }
    if (type == 'post') return '/posts';

    return path;
  }

  String? _extractIdFromRoute(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    final path = uri?.path ?? raw;
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    return segments.last;
  }

  Future<void> _markAsRead(WidgetRef ref, String id) async {
    final authState = ref.read(authStateProvider);
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) return;
    await ApiService().put(
      '/api/notifications/$id/read',
      data: {'studentId': studentId},
    );
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final authState = ref.read(authStateProvider);
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) return;
    await ApiService().put('/api/notifications/$studentId/read-all');
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  // ── Placeholder widgets ───────────────────────────────────────────────────
  Widget _loadingWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: kPrimaryBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_off_rounded,
              color: kPrimary,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'New updates from educators will appear here.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _noFilterResults(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: kPrimaryBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.filter_list_off_rounded,
                color: kPrimary, size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            'No $_selectedFilter notifications',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different filter',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
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

// ── Group Label ────────────────────────────────────────────────────────────────
class _GroupLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _GroupLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Divider(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ],
    );
  }
}

// ── Notification Tile ──────────────────────────────────────────────────────────
class _NotificationTile extends StatefulWidget {
  final AppNotification notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final isDark = widget.isDark;
    final isUnread = !n.isRead;
    final cfg = _getTypeConfig(n.type);

    final imageUrl = n.metadata?.thumbnail ?? n.sender?.avatar;
    final relativeTime =
        n.createdAt != null ? DateFormatter.formatRelative(n.createdAt!) : '';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isUnread
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : (isDark ? const Color(0xFF1A2332) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? kPrimary.withOpacity(isDark ? 0.3 : 0.15)
                  : (isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFE2E8F0)),
              width: isUnread ? 1.2 : 0.8,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: kPrimary.withOpacity(isDark ? 0.1 : 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────────────────────────
                _NotificationAvatar(
                  imageUrl: imageUrl,
                  config: cfg,
                  isUnread: isUnread,
                ),
                const SizedBox(width: 12),

                // ── Content ─────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + unread dot
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFEF4444)
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),

                      // message
                      Text(
                        n.message,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // type chip + time
                      Row(
                        children: [
                          _TypeChip(config: cfg, isDark: isDark),
                          const SizedBox(width: 8),
                          if (relativeTime.isNotEmpty)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 11,
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFCBD5E1),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  relativeTime,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Notification Avatar ────────────────────────────────────────────────────────
class _NotificationAvatar extends StatelessWidget {
  final String? imageUrl;
  final _TypeConfig config;
  final bool isUnread;

  const _NotificationAvatar({
    this.imageUrl,
    required this.config,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        decoration: isUnread
            ? BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: config.color.withOpacity(0.3), width: 2),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AppNetworkImage(
            imageUrl: imageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withOpacity(isUnread ? 0.2 : 0.1),
            config.color.withOpacity(isUnread ? 0.1 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: isUnread
            ? Border.all(color: config.color.withOpacity(0.25), width: 1.5)
            : null,
      ),
      child: Icon(config.icon, color: config.color, size: 22),
    );
  }
}

// ── Type Chip ──────────────────────────────────────────────────────────────────
class _TypeChip extends StatelessWidget {
  final _TypeConfig config;
  final bool isDark;

  const _TypeChip({required this.config, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: config.color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 10, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: config.color,
            ),
          ),
        ],
      ),
    );
  }
}
