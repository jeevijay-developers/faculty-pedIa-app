import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/webinar_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

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
final examWebinarsProvider = FutureProvider.family
    .autoDispose<List<Webinar>, String>((ref, examType) async {
  String specializationForApi(String t) {
    switch (t.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      default:
        return t.toUpperCase();
    }
  }

  final api = ApiService();
  final specialization = specializationForApi(examType);
  final response = await api.get(
    '/api/webinars',
    queryParameters: {'specialization': specialization},
  );
  final data = response.data;

  List<dynamic> list = [];
  if (data is Map && data['data']?['webinars'] != null) {
    list = data['data']['webinars'] as List;
  } else if (data is Map && data['webinars'] != null) {
    list = data['webinars'] as List;
  } else if (data is List) {
    list = data;
  }

  return list.map((e) => Webinar.fromJson(e)).toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class ExamWebinarsScreen extends ConsumerStatefulWidget {
  final String examType;
  const ExamWebinarsScreen({super.key, required this.examType});

  @override
  ConsumerState<ExamWebinarsScreen> createState() => _ExamWebinarsScreenState();
}

class _ExamWebinarsScreenState extends ConsumerState<ExamWebinarsScreen> {
  String get _examLabel {
    switch (widget.examType.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      default:
        return widget.examType.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final webinarsAsync = ref.watch(examWebinarsProvider(widget.examType));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async =>
            ref.invalidate(examWebinarsProvider(widget.examType)),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ────────────────────────────────────────────────
            _buildSliverAppBar(context, isDark),

            // ── Content ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: webinarsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: ShimmerList(
                    itemCount: 4,
                    itemHeight: 200,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: error.toString(),
                    onRetry: () =>
                        ref.invalidate(examWebinarsProvider(widget.examType)),
                  ),
                ),
                data: (webinars) {
                  if (webinars.isEmpty) return _emptyWidget(isDark);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCountStrip(webinars, isDark),
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
  SliverAppBar _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isCollapsed = constraints.maxHeight <= kToolbarHeight + 24;

          return FlexibleSpaceBar(
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
                // one subtle circle
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
                        _examLabel.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$_examLabel Webinars',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Live sessions with top educators',
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
            title: isCollapsed
                ? Text(
                    '$_examLabel Webinars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  )
                : null,
            titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
          );
        },
      ),
    );
  }

  // ── Count strip ───────────────────────────────────────────────────────────
  Widget _buildCountStrip(List<Webinar> all, bool isDark) {
    final liveCount = all.where((w) => w.isLive).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Text(
            '${all.length} webinars',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
          if (liveCount > 0) ...[
            const SizedBox(width: 10),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFFEF4444), shape: BoxShape.circle),
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
    );
  }

  // ── Empty / No results ────────────────────────────────────────────────────
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
          const Text('No Webinars Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Check back later for upcoming webinars',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );
}

// ── Webinar Card ───────────────────────────────────────────────────────────────
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

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    return url.startsWith('/')
        ? '${AppConfig.baseUrl}$url'
        : '${AppConfig.baseUrl}/$url';
  }

  // Status config — red for live, blue for upcoming, neutral for ended
  _StatusConfig get _status {
    if (widget.webinar.isLive) {
      return const _StatusConfig(
        label: 'LIVE',
        color: Color(0xFFEF4444),
        isLive: true,
      );
    }
    if (widget.webinar.isUpcoming) {
      return const _StatusConfig(
        label: 'UPCOMING',
        color: kPrimary,
        isLive: false,
      );
    }
    return _StatusConfig(
      label: 'ENDED',
      color: widget.isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      isLive: false,
    );
  }

  String get _buttonText {
    if (widget.webinar.isLive) return 'Join Now';
    if (widget.webinar.isUpcoming) return 'Register';
    return 'View Details';
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.webinar;
    final isDark = widget.isDark;
    final imageUrl = _resolveImageUrl(w.imageUrl);
    final status = _status;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/webinar/${w.id}');
      },
      onTapCancel: () => _ctrl.reverse(),
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
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Thumbnail ─────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    // image
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback(),
                            )
                          : _imageFallback(),
                    ),
                    // subtle dark overlay
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
                    // status badge — top left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _StatusBadge(config: status),
                    ),
                    // free badge — top right
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
                          child: const Text(
                            'Free',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    // camera icon center (if no image)
                    if (imageUrl.isEmpty)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.videocam_rounded,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Card Body ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // title
                    Text(
                      w.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        height: 1.3,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 10),

                    // educator row
                    if (w.educatorName != null)
                      Row(
                        children: [
                          UserAvatar(
                            imageUrl: w.educatorImage,
                            name: w.educatorName,
                            size: 26,
                            showBorder: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            w.educatorName!,
                            style: const TextStyle(
                              color: kPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // divider
                    Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : kDivLight),

                    const SizedBox(height: 12),

                    // date + duration row
                    Row(
                      children: [
                        if (w.scheduledAt != null) ...[
                          const Icon(Icons.calendar_month_rounded,
                              size: 14, color: kPrimary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              DateFormatter.formatDateTime(w.scheduledAt!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? kText2Dark : kText2Light,
                              ),
                            ),
                          ),
                        ],
                        if (w.duration != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.timer_rounded,
                              size: 14, color: kPrimary),
                          const SizedBox(width: 4),
                          Text(
                            '${w.duration} min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? kText2Dark : kText2Light,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // CTA button — solid blue for live, outline for others
                    GestureDetector(
                      onTap: () => context.push('/webinar/${w.id}'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: w.isLive ? kPrimary : kPrimaryBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: w.isLive ? kPrimary : kPrimaryMid,
                            width: w.isLive ? 0 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              w.isLive
                                  ? Icons.videocam_rounded
                                  : w.isUpcoming
                                      ? Icons.how_to_reg_rounded
                                      : Icons.play_circle_rounded,
                              color: w.isLive ? Colors.white : kPrimary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _buttonText,
                              style: TextStyle(
                                color: w.isLive ? Colors.white : kPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
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

  Widget _imageFallback() => Container(
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );
}

// ── Status config ──────────────────────────────────────────────────────────────
class _StatusConfig {
  final String label;
  final Color color;
  final bool isLive;
  const _StatusConfig(
      {required this.label, required this.color, required this.isLive});
}

// ── Status Badge ───────────────────────────────────────────────────────────────
class _StatusBadge extends StatefulWidget {
  final _StatusConfig config;
  const _StatusBadge({required this.config});

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
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(_pulse);
    if (widget.config.isLive) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.config.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.config.isLive)
            AnimatedBuilder(
              animation: _opacity,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: widget.config.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            )
          else
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: widget.config.color,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            widget.config.label,
            style: TextStyle(
              color: widget.config.color,
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
