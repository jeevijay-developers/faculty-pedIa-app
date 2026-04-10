import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
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
final webinarsProvider = FutureProvider.autoDispose<List<Webinar>>((ref) async {
  final api = ApiService();
  final response = await api.get('/api/webinars');
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
class WebinarsScreen extends ConsumerStatefulWidget {
  const WebinarsScreen({super.key});

  @override
  ConsumerState<WebinarsScreen> createState() => _WebinarsScreenState();
}

class _WebinarsScreenState extends ConsumerState<WebinarsScreen> {
  String _statusFilter = 'All';
  String _examFilter = 'All Exams';

  static const _statusFilters = ['All', 'Live', 'Upcoming', 'Ended', 'Free'];
  static const _examFilters = ['All Exams', 'IIT-JEE', 'NEET', 'CBSE'];

  String _normalizeExam(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  List<Webinar> _applyFilter(List<Webinar> list) {
    var result = list;

    switch (_statusFilter) {
      case 'Live':
        result = result.where((w) => w.isLive).toList();
        break;
      case 'Upcoming':
        result = result.where((w) => w.isUpcoming).toList();
        break;
      case 'Ended':
        result = result.where((w) => !w.isLive && !w.isUpcoming).toList();
        break;
      case 'Free':
        result = result.where((w) => w.isFree == true).toList();
        break;
    }

    if (_examFilter != 'All Exams') {
      final t = _normalizeExam(_examFilter);
      result = result
          .where((w) =>
              w.specialization.any((s) => _normalizeExam(s).contains(t)) ||
              w.subject.any((s) => _normalizeExam(s).contains(t)))
          .toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final webinarsAsync = ref.watch(webinarsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(webinarsProvider),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverToBoxAdapter(child: _buildFilters(isDark)),
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
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(webinarsProvider),
                  ),
                ),
                data: (webinars) {
                  final filtered = _applyFilter(webinars);
                  if (webinars.isEmpty) return _emptyWidget(isDark);
                  if (filtered.isEmpty) return _noResultsWidget(isDark);

                  return Column(
                    children: [
                      _buildCountStrip(webinars, filtered, isDark),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _WebinarCard(
                          webinar: filtered[i],
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
          onTap: () {
            if (context.canPop())
              context.pop();
            else
              context.go('/home');
          },
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
                        'FACULTY PEDIA',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Webinars',
                        style: TextStyle(
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
                ? const Text(
                    'Webinars',
                    style: TextStyle(
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

  // ── Filters ───────────────────────────────────────────────────────────────
  Widget _buildFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        children: [
          // status filter chips
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _statusFilters[i];
                final active = _statusFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? kPrimary
                          : (isDark ? kSurfaceDark : kSurface),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? kPrimary
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : kDivLight),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : (isDark ? kText2Dark : kText2Light),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // exam filter chips
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _examFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _examFilters[i];
                final active = _examFilter == f;
                return GestureDetector(
                  onTap: () => setState(() => _examFilter = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? kPrimaryBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? kPrimaryMid
                            : (isDark
                                ? Colors.white.withOpacity(0.08)
                                : kDivLight),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? kPrimary
                            : (isDark ? kText2Dark : kText3Light),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Count strip ───────────────────────────────────────────────────────────
  Widget _buildCountStrip(
      List<Webinar> all, List<Webinar> filtered, bool isDark) {
    final liveCount = all.where((w) => w.isLive).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Text(
            '${filtered.length} webinars',
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

  Widget _noResultsWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.filter_list_off_rounded,
                color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No webinars found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try a different filter',
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

  String get _buttonText {
    if (widget.webinar.isLive) return 'Join Now';
    if (widget.webinar.isUpcoming) return 'Register';
    return 'View Recording';
  }

  IconData get _buttonIcon {
    if (widget.webinar.isLive) return Icons.videocam_rounded;
    if (widget.webinar.isUpcoming) return Icons.how_to_reg_rounded;
    return Icons.play_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.webinar;
    final isDark = widget.isDark;
    final imgUrl = _resolveImageUrl(w.imageUrl);

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
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: imgUrl.isNotEmpty
                          ? Image.network(imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imageFallback())
                          : _imageFallback(),
                    ),
                    // dark overlay
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
                  ],
                ),
              ),

              // ── Card body ─────────────────────────────────────────────
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

                    // educator
                    if (w.educatorName != null)
                      Row(
                        children: [
                          UserAvatar(
                            imageUrl: w.educatorImage,
                            name: w.educatorName,
                            size: 24,
                            showBorder: false,
                          ),
                          const SizedBox(width: 7),
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
                      color:
                          isDark ? Colors.white.withOpacity(0.07) : kDivLight,
                    ),

                    const SizedBox(height: 12),

                    // date + duration
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

                    // CTA — solid blue for live, outlined for others
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
                          boxShadow: w.isLive
                              ? [
                                  BoxShadow(
                                    color: kPrimary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _buttonIcon,
                              color: w.isLive ? Colors.white : kPrimary,
                              size: 16,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _buttonText,
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
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 48),
        ),
      );
}

// ── Status Badge ───────────────────────────────────────────────────────────────
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
            : const Color(0xFF94A3B8);
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
