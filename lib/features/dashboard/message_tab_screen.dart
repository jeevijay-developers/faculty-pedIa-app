import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/user_widgets.dart';

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

// ── Provider ───────────────────────────────────────────────────────────────────
final broadcastMessagesProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final response =
      await api.get('/api/notifications/$studentId?type=broadcast_message');
  final payload = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};
  final data = payload['data'] is Map<String, dynamic>
      ? payload['data'] as Map<String, dynamic>
      : payload;

  final raw = data['notifications'] ?? data['data'] ?? data;
  if (raw is! List) return const [];

  return raw
      .whereType<Map<String, dynamic>>()
      .map(AppNotification.fromJson)
      .toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class MessageTabScreen extends ConsumerWidget {
  const MessageTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messagesAsync = ref.watch(broadcastMessagesProvider);
    final totalCount =
        messagesAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);
    final unreadCount = messagesAsync.maybeWhen(
        data: (d) => d.where((m) => !m.isRead).length, orElse: () => 0);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(broadcastMessagesProvider),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────
            _buildSliverAppBar(context, isDark, totalCount, unreadCount),

            // ── Info banner ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _InfoBanner(isDark: isDark),
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: messagesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child:
                      Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(broadcastMessagesProvider),
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) return _emptyWidget(isDark);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Row(
                          children: [
                            Text(
                              '${messages.length} messages',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: kPrimary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$unreadCount new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: messages.length,
                        itemBuilder: (_, i) => _MessageCard(
                          message: messages[i],
                          isDark: isDark,
                        ),
                      ),
                    ],
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
    bool isDark,
    int total,
    int unread,
  ) {
    return SliverAppBar(
      expandedHeight: 148,
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
                    'BROADCAST',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updates from educators you follow',
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

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Broadcast updates from educators\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? kText2Dark : kText3Light,
              height: 1.5,
            ),
          ),
        ]),
      );
}

// ── Info banner ────────────────────────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  final bool isDark;
  const _InfoBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mail_outline_rounded,
                color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Broadcast Messages',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? kText1Dark : kText1Light,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Announcements sent by educators you follow.',
                  style: TextStyle(
                    fontSize: 12,
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
}

// ── Message card ───────────────────────────────────────────────────────────────
class _MessageCard extends StatefulWidget {
  final AppNotification message;
  final bool isDark;
  const _MessageCard({required this.message, required this.isDark});

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard>
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
    final m = widget.message;
    final isDark = widget.isDark;
    final senderName = m.sender?.name ?? 'Educator';
    final avatar = m.sender?.avatar;
    final when =
        m.createdAt != null ? DateFormatter.formatDateTime(m.createdAt!) : '';
    final isUnread = !m.isRead;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isUnread
                  ? kPrimaryMid
                  : (isDark ? Colors.white.withOpacity(0.06) : kDivLight),
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Sender row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    // avatar with blue ring
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary, width: 1.5),
                      ),
                      child: UserAvatar(
                        imageUrl: avatar,
                        name: senderName,
                        size: 36,
                        showBorder: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? kText1Dark : kText1Light,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (when.isNotEmpty)
                            Text(
                              when,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? kText2Dark : kText3Light,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // unread dot
                    if (isUnread)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: kPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
              ),

              // ── Message body ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title with optional unread badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? kText1Dark : kText1Light,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : kPrimaryBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: kPrimaryMid),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kPrimary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: isDark ? kText2Dark : kText2Light,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
