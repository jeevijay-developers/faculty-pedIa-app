import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_service.dart';
import '../../core/utils/date_formatter.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/models/webinar_model.dart';
import '../../shared/widgets/state_widgets.dart';

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
final dashboardWebinarsProvider =
    FutureProvider.autoDispose<List<Webinar>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final responses = await Future.wait([
    api.get('/api/students/$studentId'),
    api.get('/api/webinars'),
  ]);

  final sp = responses[0].data is Map<String, dynamic>
      ? responses[0].data as Map<String, dynamic>
      : <String, dynamic>{};
  final sd = sp['data'] is Map<String, dynamic>
      ? sp['data'] as Map<String, dynamic>
      : sp;
  final enrolledIds = _extractWebinarIds(sd);
  if (enrolledIds.isEmpty) return const [];

  final wp = responses[1].data is Map<String, dynamic>
      ? responses[1].data as Map<String, dynamic>
      : <String, dynamic>{};
  final wd = wp['data']?['webinars'] ?? wp['webinars'] ?? wp;
  final list = wd is List ? wd : const <dynamic>[];

  return list
      .map((e) => Webinar.fromJson(e))
      .where((w) => enrolledIds.contains(w.id))
      .toList();
});

Set<String> _extractWebinarIds(Map<String, dynamic> data) {
  final raw = data['webinars'] ??
      data['registeredWebinars'] ??
      data['enrolledWebinars'] ??
      data['webinarIds'] ??
      data['webinarId'] ??
      data['webinar'];

  final ids = <String>{};
  void addId(dynamic v) {
    if (v == null) return;
    if (v is String && v.isNotEmpty) {
      ids.add(v);
      return;
    }
    if (v is Map) {
      final c = v['webinarId'] ?? v['_id'] ?? v['id'];
      if (c is String && c.isNotEmpty) {
        ids.add(c);
        return;
      }
      if (c is Map) {
        final n = c['_id'] ?? c['id'];
        if (n is String && n.isNotEmpty) ids.add(n);
      }
    }
  }

  if (raw is List) {
    for (final e in raw) addId(e);
  } else
    addId(raw);
  return ids;
}

// ── Screen ─────────────────────────────────────────────────────────────────────
class WebinarTabScreen extends ConsumerWidget {
  const WebinarTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = auth.user?.displayName?.split(' ').first ?? 'Student';
    final webinarsAsync = ref.watch(dashboardWebinarsProvider);
    final totalCount =
        webinarsAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);
    final liveCount = webinarsAsync.maybeWhen(
        data: (d) => d.where((w) => w.isLive).length, orElse: () => 0);

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(dashboardWebinarsProvider),
        child: CustomScrollView(
          slivers: [
            // ── Collapsible hero AppBar ──────────────────────────────
            _buildSliverAppBar(context, isDark, firstName, totalCount),

            SliverToBoxAdapter(
              child: webinarsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child:
                      Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(dashboardWebinarsProvider),
                  ),
                ),
                data: (webinars) {
                  if (webinars.isEmpty) return _emptyWidget(isDark);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              '${webinars.length} webinars',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                            ),
                            if (liveCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$liveCount live now',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
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
                        itemCount: webinars.length,
                        itemBuilder: (_, i) => _WebinarCard(
                          webinar: webinars[i],
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
    String firstName,
    int count,
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
                    'MY WEBINARS',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Hello, $firstName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your enrolled webinars & live sessions',
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
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.videocam_off_rounded,
                color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No webinars enrolled',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Enrolled webinars will appear here.',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );
}

// ── Webinar card ───────────────────────────────────────────────────────────────
class _WebinarCard extends StatefulWidget {
  final Webinar webinar;
  final bool isDark;
  const _WebinarCard({required this.webinar, required this.isDark});

  @override
  State<_WebinarCard> createState() => _WebinarCardState();
}

class _WebinarCardState extends State<_WebinarCard>
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

  String get _btnText {
    if (widget.webinar.isLive) return 'Join Now';
    if (widget.webinar.isUpcoming) return 'View Details';
    return 'View Recording';
  }

  IconData get _btnIcon {
    if (widget.webinar.isLive) return Icons.videocam_rounded;
    if (widget.webinar.isUpcoming) return Icons.info_outline_rounded;
    return Icons.play_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.webinar;
    final isDark = widget.isDark;

    final dateText = w.scheduledAt != null
        ? DateFormatter.formatDateTime(w.scheduledAt!)
        : 'TBA';
    final durationText = w.duration != null ? '${w.duration} min' : 'TBA';
    final subject = w.subject.isNotEmpty ? w.subject.first : '—';
    final seats = w.maxAttendees != null
        ? '${w.registeredCount ?? 0}/${w.maxAttendees} seats'
        : '${w.registeredCount ?? 0} enrolled';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/webinar/${w.id}');
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? kSurfaceDark : kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ────────────────────────────────────────
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 165,
                      width: double.infinity,
                      child: w.imageUrl.isNotEmpty
                          ? Image.network(w.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallback())
                          : _fallback(),
                    ),
                    // gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.45),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                    ),
                    // status badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(webinar: w),
                    ),
                    // free badge
                    if (w.isFree == true)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title
                    Text(
                      w.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (w.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        w.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark ? kText2Dark : kText2Light,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // info grid
                    _buildInfoGrid(
                      dateText: dateText,
                      durationText: durationText,
                      subject: subject,
                      seats: seats,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // divider
                    Divider(
                      height: 1,
                      color:
                          isDark ? Colors.white.withOpacity(0.07) : kDivLight,
                    ),

                    const SizedBox(height: 14),

                    // CTA row
                    Row(
                      children: [
                        // view details outline btn
                        GestureDetector(
                          onTap: () => context.push('/webinar/${w.id}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.04)
                                  : kPrimaryBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kPrimaryMid),
                            ),
                            child: const Text('Details',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                )),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // main CTA
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openMeetingLink(context, w),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: w.isLive ? kPrimary : kPrimaryBg,
                                borderRadius: BorderRadius.circular(12),
                                border: w.isLive
                                    ? null
                                    : Border.all(color: kPrimaryMid),
                                boxShadow: w.isLive
                                    ? [
                                        BoxShadow(
                                          color: kPrimary.withOpacity(0.28),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _btnIcon,
                                    color: w.isLive ? Colors.white : kPrimary,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _btnText,
                                    style: TextStyle(
                                      color: w.isLive ? Colors.white : kPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }

  // ── Info grid (2×2) ───────────────────────────────────────────────────────
  Widget _buildInfoGrid({
    required String dateText,
    required String durationText,
    required String subject,
    required String seats,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoCell(Icons.calendar_month_rounded, dateText, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCell(Icons.timer_rounded, durationText, isDark),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _infoCell(Icons.menu_book_rounded, subject, isDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCell(Icons.people_rounded, seats, isDark),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCell(IconData icon, String text, bool isDark) => Row(
        children: [
          Icon(icon, size: 13, color: isDark ? kText2Dark : kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? kText2Dark : kText2Light,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  Widget _fallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 48),
        ),
      );

  Future<void> _openMeetingLink(BuildContext context, Webinar webinar) async {
    final link = webinar.meetingLink?.trim() ?? '';
    if (link.isEmpty) {
      _snack(context, 'Meeting link is not available yet.');
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _snack(context, 'Invalid meeting link.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _snack(context, 'Unable to open meeting link.');
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1E293B),
    ));
  }
}

// ── Status badge ───────────────────────────────────────────────────────────────
class _StatusBadge extends StatefulWidget {
  final Webinar webinar;
  const _StatusBadge({required this.webinar});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(_pulse);
    if (widget.webinar.isLive) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.webinar;
    final isLive = w.isLive;
    final dotColor = isLive
        ? const Color(0xFFEF4444)
        : w.isUpcoming
            ? kPrimary
            : kText3Light;
    final label = isLive
        ? 'LIVE'
        : w.isUpcoming
            ? 'UPCOMING'
            : 'ENDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.52),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dotColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          isLive
              ? AnimatedBuilder(
                  animation: _opacity,
                  builder: (_, __) => Opacity(
                    opacity: _opacity.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                          color: dotColor, shape: BoxShape.circle),
                    ),
                  ),
                )
              : Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
          Text(
            label,
            style: TextStyle(
              color: dotColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
