import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/educator_model.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/models/test_series_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';
import '../../../loading/skeleton.educator.dart';

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

// ── Providers ──────────────────────────────────────────────────────────────────
final educatorDetailProvider =
    FutureProvider.family.autoDispose<Educator, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/educators/$id');
  final data = response.data;
  Map<String, dynamic> ed = {};
  if (data is Map && data['data'] is Map && data['data']['educator'] != null) {
    ed = Map<String, dynamic>.from(data['data']['educator']);
  } else if (data is Map && data['educator'] != null) {
    ed = Map<String, dynamic>.from(data['educator']);
  } else if (data is Map) {
    ed = Map<String, dynamic>.from(data);
  }
  return Educator.fromJson(ed);
});

final educatorCoursesProvider =
    FutureProvider.family.autoDispose<List<Course>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/courses/educator/$id');
  final data = response.data;
  List<dynamic> list = [];
  if (data is Map && data['data'] is Map && data['data']['courses'] != null) {
    list = data['data']['courses'] as List;
  } else if (data is Map && data['courses'] != null) {
    list = data['courses'] as List;
  } else if (data is List) {
    list = data;
  }
  final courses = list.map((e) => Course.fromJson(e)).toList();
  final hasReviewsField = list.any((e) => e is Map && e.containsKey('reviews'));
  if (courses.isEmpty || hasReviewsField) return courses;

  return Future.wait(courses.map((course) async {
    final dr = await api.get('/api/courses/${course.id}');
    final dd = dr.data;
    Map<String, dynamic> cd = {};
    if (dd is Map && dd['data'] is Map)
      cd = Map<String, dynamic>.from(dd['data']);
    else if (dd is Map && dd['course'] != null)
      cd = Map<String, dynamic>.from(dd['course']);
    else if (dd is Map) cd = Map<String, dynamic>.from(dd);
    return Course.fromJson(cd);
  }));
});

final educatorTestSeriesProvider = FutureProvider.family
    .autoDispose<List<TestSeries>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/test-series/educator/$id');
  final data = response.data;
  List<dynamic> list = [];
  if (data is Map && data['testSeries'] != null)
    list = data['testSeries'] as List;
  else if (data is List) list = data;
  return list.map((e) => TestSeries.fromJson(e)).toList();
});

final educatorWebinarsProvider =
    FutureProvider.family.autoDispose<List<dynamic>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/webinars/educator/$id');
  final data = response.data;
  List<dynamic> list = [];
  if (data is Map && data['data'] is Map && data['data']['webinars'] != null)
    list = data['data']['webinars'] as List;
  else if (data is Map && data['webinars'] != null)
    list = data['webinars'] as List;
  else if (data is List) list = data;
  return list;
});

// ── Main screen ────────────────────────────────────────────────────────────────
class EducatorProfileScreen extends ConsumerWidget {
  final String educatorId;
  const EducatorProfileScreen({super.key, required this.educatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorDetailProvider(educatorId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return async.when(
      loading: () => const EducatorProfileSkeleton(),
      error: (e, _) => Scaffold(
        backgroundColor: isDark ? kBgDark : kBgLight,
        appBar: AppBar(
          backgroundColor: isDark ? kBgDark : kBgLight,
          elevation: 0,
          leading: _backBtn(context, isDark),
        ),
        body: _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(educatorDetailProvider(educatorId)),
          isDark: isDark,
        ),
      ),
      data: (educator) => _ProfileBody(
        educator: educator,
        educatorId: educatorId,
      ),
    );
  }

  Widget _backBtn(BuildContext context, bool isDark) => Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? kSurfaceDark : kPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kPrimary, size: 18),
          ),
        ),
      );
}

// ── Profile body ───────────────────────────────────────────────────────────────
class _ProfileBody extends ConsumerStatefulWidget {
  final Educator educator;
  final String educatorId;

  const _ProfileBody({required this.educator, required this.educatorId});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFollowing = false;
  bool _isFollowingInitialized = false;
  bool _bioExpanded = false;
  int _myRating = 0;
  int _followerCount = 0;
  VideoPlayerController? _videoCtrl;
  WebViewController? _vimeoCtrl;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _followerCount = widget.educator.followerCount;
    _initVideo(widget.educator);
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ProfileBody old) {
    super.didUpdateWidget(old);
    if (old.educatorId != widget.educatorId) {
      _isFollowingInitialized = false;
      _isFollowing = false;
    }
    if (old.educator.introVideoLink != widget.educator.introVideoLink) {
      _initVideo(widget.educator);
    }
    if (old.educator.followerCount != widget.educator.followerCount) {
      _followerCount = widget.educator.followerCount;
    }
  }

  bool? _computeFollowing(AuthState auth) {
    final sid = auth.student?.id;
    if (sid == null || sid.isEmpty) return null;
    return widget.educator.followerIds.contains(sid) ||
        (auth.student?.followingEducators.contains(widget.educator.id) ??
            false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFollowing = _isFollowingInitialized
        ? _isFollowing
        : (_computeFollowing(auth) ?? false);
    final e = widget.educator;
    final hasPayPerHour = (e.payPerHourFee ?? 0) > 0;
    final coursesAsync = ref.watch(educatorCoursesProvider(widget.educatorId));
    final tsAsync = ref.watch(educatorTestSeriesProvider(widget.educatorId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? kBgDark : kBgLight,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            // AppBar
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? kBgDark : kSurface,
              surfaceTintColor: Colors.transparent,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? kSurfaceDark : kPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: kPrimary, size: 18),
                  ),
                ),
              ),
              title: Text(
                'Educator Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? kText1Dark : kText1Light,
                ),
              ),
              actions: [],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0.5),
                child:
                    Divider(height: 0.5, color: Colors.grey.withOpacity(0.12)),
              ),
            ),

            // Header card
            SliverToBoxAdapter(
              child: _ProfileHeaderCard(
                educator: e,
                isFollowing: isFollowing,
                isDark: isDark,
                onFollowTap: _toggleFollow,
              ),
            ),

            // Stats grid
            SliverToBoxAdapter(
              child: _StatsGrid(
                educator: e,
                educatorId: widget.educatorId,
                followerCount: _followerCount,
                isDark: isDark,
              ),
            ),

            // Book 1:1 session
            if (hasPayPerHour)
              SliverToBoxAdapter(
                child: _BookSessionCard(educator: e, isDark: isDark),
              ),

            // Intro video
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildVideo(e, isDark),
              ),
            ),

            // About
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _AboutSection(
                  bio: e.bio ?? '',
                  subjects: _subjectChips(e),
                  experience: e.displayExperience,
                  expanded: _bioExpanded,
                  isDark: isDark,
                  onToggle: () => setState(() => _bioExpanded = !_bioExpanded),
                ),
              ),
            ),

            // Background
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _BackgroundSection(
                  qualifications: e.qualifications,
                  workExperience: e.workExperience,
                  isDark: isDark,
                ),
              ),
            ),

            // Ratings
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _RatingsSection(
                  educator: e,
                  coursesAsync: coursesAsync,
                  tsAsync: tsAsync,
                  myRating: _myRating,
                  isDark: isDark,
                  onRate: _submitRating,
                ),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabDelegate(
                isDark: isDark,
                tabBar: TabBar(
                  controller: _tabCtrl,
                  labelColor: kPrimary,
                  unselectedLabelColor: isDark ? kText2Dark : kText2Light,
                  indicatorColor: kPrimary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor:
                      isDark ? Colors.white.withOpacity(0.08) : kDivLight,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  tabs: const [
                    Tab(text: 'Courses'),
                    Tab(text: 'Webinars'),
                    Tab(text: 'Test Series'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _CoursesTab(
                  educatorId: widget.educatorId,
                  educatorName: e.displayName,
                  isDark: _isDark()),
              _WebinarsTab(
                  educatorId: widget.educatorId,
                  educatorName: e.displayName,
                  isDark: _isDark()),
              _TestSeriesTab(
                  educatorId: widget.educatorId,
                  educatorName: e.displayName,
                  isDark: _isDark()),
            ],
          ),
        ),
      ),
    );
  }

  bool _isDark() => Theme.of(context).brightness == Brightness.dark;

  // ── Video ──────────────────────────────────────────────────────────────────
  Widget _buildVideo(Educator e, bool isDark) {
    final url = _resolveUrl(e.introVideoLink ?? '');
    if (url.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline_rounded, color: kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Intro video not available.',
                  style: TextStyle(
                      fontSize: 13, color: isDark ? kText2Dark : kText2Light)),
            ),
          ],
        ),
      );
    }

    final vimeoUrl = _resolveVimeoUrl(url);
    if (vimeoUrl.isNotEmpty && _vimeoCtrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
            height: 210,
            width: double.infinity,
            child: WebViewWidget(controller: _vimeoCtrl!)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 210,
            width: double.infinity,
            child: _isVideoReady && _videoCtrl != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoCtrl!.value.size.width,
                      height: _videoCtrl!.value.size.height,
                      child: VideoPlayer(_videoCtrl!),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimary, kPrimaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.videocam_rounded,
                          color: Colors.white24, size: 56),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_videoCtrl == null) return;
              setState(() {
                _videoCtrl!.value.isPlaying
                    ? _videoCtrl!.pause()
                    : _videoCtrl!.play();
              });
            },
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: kPrimary.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Icon(
                _videoCtrl != null && _videoCtrl!.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.play_circle_rounded,
                      color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Intro Video',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<String> _subjectChips(Educator e) {
    final chips = <String>[
      ...e.specialization.map(_titleCase),
      ...e.subject.map(_titleCase),
    ];
    return chips.where((v) => v.isNotEmpty).toSet().toList();
  }

  String _titleCase(String v) => v
      .replaceAll('-', ' ')
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
      .join(' ')
      .trim();

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    return url.startsWith('/')
        ? '${AppConfig.baseUrl}$url'
        : '${AppConfig.baseUrl}/$url';
  }

  bool _isVimeo(String url) =>
      url.contains('vimeo.com') || url.contains('player.vimeo.com');

  String _resolveVimeoUrl(String url) {
    final resolved = _resolveUrl(url);
    if (resolved.contains('player.vimeo.com')) return resolved;
    final match = RegExp(r'(\d{6,})').firstMatch(resolved);
    final videoId = match?.group(1);
    if (videoId == null || videoId.isEmpty) return '';
    return 'https://player.vimeo.com/video/$videoId?playsinline=1&autoplay=0';
  }

  Future<void> _initVideo(Educator e) async {
    final url = _resolveUrl(e.introVideoLink ?? '');
    if (url.isEmpty) {
      if (mounted)
        setState(() {
          _isVideoReady = false;
          _vimeoCtrl = null;
        });
      return;
    }
    if (_isVimeo(url)) {
      final embed = _resolveVimeoUrl(url);
      if (embed.isNotEmpty) {
        _vimeoCtrl = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..loadRequest(Uri.parse(embed));
      }
      if (mounted) setState(() => _isVideoReady = false);
      return;
    }
    if (_videoCtrl != null && _videoCtrl!.dataSource == url) return;
    await _videoCtrl?.dispose();
    _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoCtrl!.initialize();
      if (mounted) setState(() => _isVideoReady = true);
    } catch (_) {
      if (mounted) setState(() => _isVideoReady = false);
    }
  }

  // ── Follow ─────────────────────────────────────────────────────────────────
  Future<void> _toggleFollow() async {
    final auth = ref.read(authStateProvider);
    final sid = auth.student?.id;
    if (sid == null || sid.isEmpty) {
      _snack('Please log in as a student to follow.');
      return;
    }
    final api = ApiService();
    final wasFollowing = _isFollowingInitialized
        ? _isFollowing
        : (_computeFollowing(auth) ?? false);
    final prevCount = _followerCount;

    setState(() {
      _isFollowingInitialized = true;
      _isFollowing = !wasFollowing;
      _followerCount = (_followerCount + (wasFollowing ? -1 : 1))
          .clamp(0, double.maxFinite.toInt());
    });

    try {
      Response resp;
      if (wasFollowing) {
        resp = await api.delete('/api/students/$sid/unfollow',
            data: {'educatorId': widget.educatorId});
      } else {
        resp = await api.post('/api/students/$sid/follow',
            data: {'educatorId': widget.educatorId});
      }
      final latestCount = _parseFollowerCount(resp.data);
      if (latestCount != null && mounted) {
        setState(() => _followerCount = latestCount);
      }
    } catch (e) {
      if (e is DioException) {
        final msg = _parseErrorMsg(e.response?.data);
        if (wasFollowing && msg.contains('not following')) {
          if (mounted)
            setState(() {
              _isFollowing = false;
              _followerCount = prevCount;
            });
          return;
        }
        if (!wasFollowing && msg.contains('already following')) {
          if (mounted)
            setState(() {
              _isFollowing = true;
              _followerCount = prevCount;
            });
          return;
        }
      }
      if (mounted)
        setState(() {
          _isFollowing = wasFollowing;
          _followerCount = prevCount;
        });
      _snack('Failed to update follow status.');
    }
  }

  int? _parseFollowerCount(dynamic data) {
    if (data is Map && data['data'] is Map) {
      final c = data['data']['followerCount'];
      if (c is int) return c;
      if (c is num) return c.toInt();
    }
    return null;
  }

  String _parseErrorMsg(dynamic data) {
    if (data is Map) {
      final m = data['message'];
      if (m is String) return m.toLowerCase();
    }
    return '';
  }

  // ── Rating ─────────────────────────────────────────────────────────────────
  Future<void> _submitRating(int rating) async {
    final auth = ref.read(authStateProvider);
    final sid = auth.student?.id;
    if (sid == null || sid.isEmpty) {
      _snack('Please log in as a student to rate.');
      return;
    }
    try {
      await ApiService().post(
        '/api/educators/${widget.educatorId}/rating',
        data: {'studentId': sid, 'rating': rating},
      );
      if (mounted) setState(() => _myRating = rating);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          _snack('You must be enrolled in an activity to rate.');
          return;
        }
        final d = e.response?.data;
        final m = d is Map ? d['message']?.toString() : null;
        if (m != null && m.isNotEmpty) {
          _snack(m);
          return;
        }
      }
      _snack('Failed to submit rating.');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1E293B),
    ));
  }
}

// ── Profile header card ────────────────────────────────────────────────────────
class _ProfileHeaderCard extends StatelessWidget {
  final Educator educator;
  final bool isFollowing;
  final bool isDark;
  final VoidCallback onFollowTap;

  const _ProfileHeaderCard({
    required this.educator,
    required this.isFollowing,
    required this.isDark,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final name =
        educator.displayName.isNotEmpty ? educator.displayName : 'Educator';
    final handle = '@${name.toLowerCase().replaceAll(' ', '_')}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar + rating badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimary, width: 2),
                ),
                child: UserAvatar(
                  imageUrl: educator.imageUrl,
                  name: educator.displayName,
                  size: 84,
                  showBorder: false,
                ),
              ),
              Positioned(
                bottom: 0,
                right: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: kPrimary.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 3),
                      Text(
                        educator.rating?.average?.toStringAsFixed(1) ?? '0.0',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            name,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: isDark ? kText1Dark : kText1Light,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            handle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? kText2Dark : kText3Light,
            ),
          ),

          const SizedBox(height: 18),

          // Subject pills
          if (educator.subject.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: educator.subject
                  .take(3)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : kPrimaryBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : kPrimaryMid,
                          ),
                        ),
                        child: Text(s,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark ? kText2Dark : kPrimary,
                            )),
                      ))
                  .toList(),
            ),

          const SizedBox(height: 18),

          // Follow button
          GestureDetector(
            onTap: onFollowTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              decoration: BoxDecoration(
                color: isFollowing ? kPrimaryBg : kPrimary,
                borderRadius: BorderRadius.circular(16),
                border: isFollowing ? Border.all(color: kPrimaryMid) : null,
                boxShadow: isFollowing
                    ? []
                    : [
                        BoxShadow(
                          color: kPrimary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isFollowing ? kPrimary : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats grid ─────────────────────────────────────────────────────────────────
class _StatsGrid extends ConsumerWidget {
  final Educator educator;
  final String educatorId;
  final int? followerCount;
  final bool isDark;

  const _StatsGrid({
    required this.educator,
    required this.educatorId,
    required this.isDark,
    this.followerCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesCount = ref
        .watch(educatorCoursesProvider(educatorId))
        .maybeWhen(data: (c) => c.length, orElse: () => 0);
    final tsCount = ref
        .watch(educatorTestSeriesProvider(educatorId))
        .maybeWhen(data: (t) => t.length, orElse: () => 0);
    final webinarCount = ref
        .watch(educatorWebinarsProvider(educatorId))
        .maybeWhen(data: (w) => w.length, orElse: () => 0);
    final fCount = followerCount ?? educator.followerCount;

    final stats = [
      _StatItem(Icons.menu_book_rounded, '$coursesCount', 'Courses'),
      _StatItem(Icons.assignment_rounded, '$tsCount', 'Test Series'),
      _StatItem(Icons.videocam_rounded, '$webinarCount', 'Webinars'),
      _StatItem(Icons.people_rounded, _fmtCount(fCount), 'Followers'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: stats.map((s) {
          final isLast = s == stats.last;
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

  String _fmtCount(int c) {
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return '$c';
  }
}

class _StatItem {
  final IconData icon;
  final String value, label;
  const _StatItem(this.icon, this.value, this.label);
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: kPrimary, size: 17),
          ),
          const SizedBox(height: 8),
          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: kPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? kText2Dark : kText3Light,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Book 1:1 ──────────────────────────────────────────────────────────────────
class _BookSessionCard extends StatelessWidget {
  final Educator educator;
  final bool isDark;
  const _BookSessionCard({required this.educator, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fee = educator.payPerHourFee ?? 0;
    if (fee <= 0) return const SizedBox.shrink();
    final feeText =
        fee % 1 == 0 ? fee.toStringAsFixed(0) : fee.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border(
          left: const BorderSide(color: kPrimary, width: 3.5),
          top: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight),
          right: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight),
          bottom: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : kDivLight),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book 1:1 Session',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? kText1Dark : kText1Light,
                    )),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '₹$feeText ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: kPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      TextSpan(
                        text: '/ hour',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? kText2Dark : kText2Light,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: kPrimaryBg,
                shape: BoxShape.circle,
                border: Border.all(color: kPrimaryMid),
              ),
              child: const Icon(Icons.calendar_today_rounded,
                  color: kPrimary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── About section ──────────────────────────────────────────────────────────────
class _AboutSection extends StatelessWidget {
  final String bio;
  final List<String> subjects;
  final String experience;
  final bool expanded;
  final bool isDark;
  final VoidCallback onToggle;

  const _AboutSection({
    required this.bio,
    required this.subjects,
    required this.experience,
    required this.expanded,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = bio.trim();
    final hasBio = trimmed.isNotEmpty;
    final isLong = trimmed.length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('About Me',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const Spacer(),
            if (experience.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDark ? Colors.white.withOpacity(0.08) : kPrimaryMid,
                  ),
                ),
                child: Text('$experience Exp',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    )),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasBio
                    ? (expanded || !isLong
                        ? trimmed
                        : '${trimmed.substring(0, 180)}…')
                    : 'No bio added yet.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.65,
                  color: isDark ? kText2Dark : kText2Light,
                ),
              ),
              if (hasBio && isLong) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onToggle,
                  child: Text(
                    expanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontSize: 13,
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: subjects
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : kPrimaryBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : kPrimaryMid,
                              ),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? kText2Dark : kPrimary,
                                )),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Background section ─────────────────────────────────────────────────────────
class _BackgroundSection extends StatelessWidget {
  final List<Qualification> qualifications;
  final List<WorkExperience> workExperience;
  final bool isDark;

  const _BackgroundSection({
    required this.qualifications,
    required this.workExperience,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Background',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isDark ? kText1Dark : kText1Light,
            )),
        const SizedBox(height: 10),
        if (workExperience.isEmpty && qualifications.isEmpty)
          _emptyCard('No background details added yet.', isDark),
        ...workExperience.map((w) => _BackgroundTile(
              title: w.title ?? 'Experience',
              institution: w.company ?? '',
              year: w.duration,
              isExperience: true,
              isDark: isDark,
            )),
        ...qualifications.map((q) => _BackgroundTile(
              title: q.title ?? q.degree ?? 'Qualification',
              institution: q.institution,
              year: q.year,
              isExperience: false,
              isDark: isDark,
            )),
      ],
    );
  }

  Widget _emptyCard(String msg, bool isDark) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
        ),
        child: Text(msg,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? kText2Dark : kText2Light,
            )),
      );
}

class _BackgroundTile extends StatelessWidget {
  final String title;
  final String? institution;
  final String? year;
  final bool isExperience;
  final bool isDark;

  const _BackgroundTile({
    required this.title,
    required this.institution,
    required this.year,
    required this.isExperience,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExperience ? Icons.work_rounded : Icons.school_rounded,
              color: kPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isDark ? kText1Dark : kText1Light,
                    )),
                if (institution != null && institution!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(institution!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? kText2Dark : kText2Light,
                      )),
                ],
              ],
            ),
          ),
          if (year != null && year!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : kDivLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(year!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? kText2Dark : kText2Light,
                  )),
            ),
        ],
      ),
    );
  }
}

// ── Ratings section ────────────────────────────────────────────────────────────
class _RatingsSection extends StatelessWidget {
  final Educator educator;
  final AsyncValue<List<Course>> coursesAsync;
  final AsyncValue<List<TestSeries>> tsAsync;
  final int myRating;
  final bool isDark;
  final ValueChanged<int> onRate;

  const _RatingsSection({
    required this.educator,
    required this.coursesAsync,
    required this.tsAsync,
    required this.myRating,
    required this.isDark,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final avg = educator.rating?.average ?? 0;
    final count = educator.rating?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ratings & Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const Spacer(),
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 4),
            Text(avg.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const SizedBox(width: 4),
            Text('($count)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? kText2Dark : kText3Light,
                )),
          ],
        ),
        const SizedBox(height: 12),

        // Your rating
        Row(
          children: [
            Text('Your Rating',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? kText2Dark : kText2Light,
                )),
            const SizedBox(width: 12),
            ...List.generate(5, (i) {
              final v = i + 1;
              final filled = v <= myRating;
              return GestureDetector(
                onTap: () => onRate(v),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled
                        ? const Color(0xFFF59E0B)
                        : (isDark ? kText2Dark : kText3Light),
                    size: 26,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Reviews
        _buildReviews(),
      ],
    );
  }

  Widget _buildReviews() {
    return coursesAsync.when(
      loading: () => Column(children: [
        _shimmerCard(),
        const SizedBox(height: 10),
        _shimmerCard(),
      ]),
      error: (e, _) => _infoCard('Failed to load reviews', e.toString()),
      data: (courses) => tsAsync.when(
        loading: () => Column(children: [
          _shimmerCard(),
          const SizedBox(height: 10),
          _shimmerCard(),
        ]),
        error: (e, _) => _infoCard('Failed to load reviews', e.toString()),
        data: (series) {
          final reviews = [
            ..._fromCourses(courses),
            ..._fromSeries(series),
          ]..sort((a, b) => (b.updatedAt ?? DateTime(0))
              .compareTo(a.updatedAt ?? DateTime(0)));

          if (reviews.isEmpty) {
            return _infoCard('No reviews yet',
                'Reviews appear after students rate courses or tests.');
          }
          return Column(
            children: reviews
                .take(4)
                .map((r) => _ReviewCard(review: r, isDark: isDark))
                .toList(),
          );
        },
      ),
    );
  }

  List<_Review> _fromCourses(List<Course> courses) {
    final out = <_Review>[];
    for (final c in courses) {
      for (final r in c.reviews) {
        if ((r.comment ?? '').trim().isEmpty) continue;
        out.add(_Review(
          source: c.title,
          name: r.name ?? 'Student',
          avatar: r.avatar,
          rating: r.rating ?? 0,
          comment: r.comment ?? '',
          updatedAt: r.updatedAt ?? r.createdAt,
        ));
      }
    }
    return out;
  }

  List<_Review> _fromSeries(List<TestSeries> series) {
    final out = <_Review>[];
    for (final ts in series) {
      for (final r in ts.reviews) {
        if ((r.comment ?? '').trim().isEmpty) continue;
        out.add(_Review(
          source: ts.title,
          name: r.name ?? 'Student',
          avatar: r.avatar,
          rating: r.rating ?? 0,
          comment: r.comment ?? '',
          updatedAt: r.updatedAt ?? r.createdAt,
        ));
      }
    }
    return out;
  }

  Widget _shimmerCard() => const ShimmerCard(height: 88);

  Widget _infoCard(String title, String sub) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const SizedBox(height: 4),
            Text(sub,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? kText2Dark : kText2Light,
                )),
          ],
        ),
      );
}

class _Review {
  final String source, name, comment;
  final String? avatar;
  final double rating;
  final DateTime? updatedAt;
  const _Review({
    required this.source,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.updatedAt,
  });
}

class _ReviewCard extends StatelessWidget {
  final _Review review;
  final bool isDark;
  const _ReviewCard({required this.review, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryBg,
            backgroundImage: review.avatar != null && review.avatar!.isNotEmpty
                ? NetworkImage(review.avatar!)
                : null,
            child: review.avatar == null || review.avatar!.isEmpty
                ? Text(
                    review.name.isNotEmpty ? review.name[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(review.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? kText1Dark : kText1Light,
                          )),
                    ),
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 3),
                    Text(review.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? kText2Dark : kText2Light,
                        )),
                  ],
                ),
                const SizedBox(height: 3),
                Text(review.source,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? kText2Dark : kText3Light,
                    )),
                const SizedBox(height: 6),
                Text(review.comment,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: isDark ? kText2Dark : kText2Light,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab views ──────────────────────────────────────────────────────────────────
class _CoursesTab extends ConsumerWidget {
  final String educatorId, educatorName;
  final bool isDark;
  const _CoursesTab({
    required this.educatorId,
    required this.educatorName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorCoursesProvider(educatorId));
    return async.when(
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('Failed to load courses', isDark),
      data: (courses) {
        final oto = courses
            .where((c) => c.courseType == 'one-to-one' || c.courseType == 'OTO')
            .toList();
        final ota = courses
            .where((c) => c.courseType == 'one-to-all' || c.courseType == 'OTA')
            .toList();

        if (oto.isEmpty && ota.isEmpty) {
          return _emptyState('No courses yet', isDark);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            if (oto.isNotEmpty) ...[
              _tabHeader('One to One', 'Personalized live sessions', isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: oto.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _CourseCard(course: oto[i], isDark: isDark),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (ota.isNotEmpty) ...[
              _tabHeader('One to All', 'Interactive group classes', isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 232,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: ota.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _CourseCard(course: ota[i], isDark: isDark),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _WebinarsTab extends ConsumerWidget {
  final String educatorId, educatorName;
  final bool isDark;
  const _WebinarsTab({
    required this.educatorId,
    required this.educatorName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorWebinarsProvider(educatorId));
    return async.when(
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('Failed to load webinars', isDark),
      data: (list) {
        if (list.isEmpty) return _emptyState('No webinars yet', isDark);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _tabHeader('Webinars by $educatorName', 'Live & upcoming sessions',
                isDark),
            const SizedBox(height: 12),
            ...list.take(6).map((w) => _WebinarRow(webinar: w, isDark: isDark)),
          ],
        );
      },
    );
  }
}

class _TestSeriesTab extends ConsumerWidget {
  final String educatorId, educatorName;
  final bool isDark;
  const _TestSeriesTab({
    required this.educatorId,
    required this.educatorName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(educatorTestSeriesProvider(educatorId));
    return async.when(
      loading: () => _loadingList(),
      error: (e, _) => _emptyState('Failed to load test series', isDark),
      data: (list) {
        if (list.isEmpty) return _emptyState('No test series yet', isDark);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _tabHeader('Test Series by $educatorName',
                'Practice with curated tests', isDark),
            const SizedBox(height: 12),
            ...list
                .take(6)
                .map((ts) => _TestSeriesRow(testSeries: ts, isDark: isDark)),
          ],
        );
      },
    );
  }
}

// ── Content cards ──────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final Course course;
  final bool isDark;
  const _CourseCard({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        width: 215,
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: course.imageUrl.isNotEmpty
                        ? Image.network(course.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _thumb())
                        : _thumb(),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kPrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          )),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(course.subject.take(1).join(', '),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? kText2Dark : kText2Light,
                      )),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        course.fees == null || course.finalPrice <= 0
                            ? 'Free'
                            : '₹${course.finalPrice.toInt()}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: course.fees == null
                              ? const Color(0xFF16A34A)
                              : kPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Enroll',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        height: 110,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child:
              Icon(Icons.play_circle_rounded, color: Colors.white24, size: 40),
        ),
      );
}

class _WebinarRow extends StatelessWidget {
  final dynamic webinar;
  final bool isDark;
  const _WebinarRow({required this.webinar, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final title = webinar['title'] ?? 'Webinar';
    final date = webinar['scheduledAt'] ?? webinar['date'] ?? '';
    final img = webinar['imageUrl'] ?? webinar['thumbnail'] ?? '';
    final id = webinar['_id'] ?? webinar['id'] ?? '';

    return GestureDetector(
      onTap: () => context.push('/webinar/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: img.isNotEmpty
                    ? Image.network(img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgFallback())
                    : _imgFallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Webinar',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        )),
                  ),
                  const SizedBox(height: 6),
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded,
                            size: 12, color: kPrimary),
                        const SizedBox(width: 4),
                        Text(_fmtDate(date),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? kText2Dark : kText2Light,
                            )),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: kPrimary),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d;
    }
  }

  Widget _imgFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white24, size: 28),
        ),
      );
}

class _TestSeriesRow extends StatelessWidget {
  final TestSeries testSeries;
  final bool isDark;
  const _TestSeriesRow({required this.testSeries, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/test-series/${testSeries.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? kSurfaceDark : kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: kPrimary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color:
                          isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Test Series',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        )),
                  ),
                  const SizedBox(height: 6),
                  Text(testSeries.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? kText1Dark : kText1Light,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.quiz_rounded,
                          size: 12, color: isDark ? kText2Dark : kText3Light),
                      const SizedBox(width: 4),
                      Text('${testSeries.totalTests ?? 0} Tests',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? kText2Dark : kText2Light,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: kPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────────
Widget _tabHeader(String title, String sub, bool isDark) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? kText1Dark : kText1Light,
                  )),
              const SizedBox(height: 2),
              Text(sub,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? kText2Dark : kText2Light,
                  )),
            ],
          ),
        ),
        const Text('See All',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: kPrimary,
            )),
      ],
    );

Widget _emptyState(String msg, bool isDark) => Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.inbox_rounded, color: kPrimary, size: 32),
            ),
            const SizedBox(height: 14),
            Text(msg,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? kText1Dark : kText1Light,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );

Widget _loadingList() => ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: List.generate(
          3,
          (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: ShimmerCard(height: 100))),
    );

// ── Error view ─────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                  color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.error_outline_rounded,
                  color: kPrimary, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Error Loading Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? kText1Dark : kText1Light,
                )),
            const SizedBox(height: 8),
            Text(message,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? kText2Dark : kText2Light,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky tab bar delegate ────────────────────────────────────────────────────
class _StickyTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final bool isDark;
  const _StickyTabDelegate({required this.tabBar, required this.isDark});

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: isDark ? kBgDark : kBgLight,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabDelegate old) => tabBar != old.tabBar;
}
