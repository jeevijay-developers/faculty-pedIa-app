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

// ─────────────────────────────────────────────
// DESIGN TOKENS — EduVantage Material You Palette
// ─────────────────────────────────────────────

class _EduColors {
  // Primary
  static const primary = Color(0xFF0050D4);
  static const onPrimary = Colors.white;
  static const primaryContainer = Color(0xFFE7E6FF);
  static const onPrimaryContainer = Color(0xFF00124A);

  // Secondary
  static const secondary = Color(0xFF5A5D85);
  static const secondaryContainer = Color(0xFFDEE0FF);
  static const onSecondaryContainer = Color(0xFF171A3D);

  // Tertiary
  static const tertiary = Color(0xFF6E3BD8);
  static const tertiaryContainer = Color(0xFFE9DDFF);
  static const onTertiaryContainer = Color(0xFF22005D);

  // Surface
  static const surface = Color(0xFFF8F5FF);
  static const onSurface = Color(0xFF1A1B2E);
  static const surfaceVariant = Color(0xFFE2E1EC);
  static const onSurfaceVariant = Color(0xFF45464F);
  static const background = Color(0xFFFDFBFF);

  // Surface containers
  static const surfaceContainerLowest = Colors.white;
  static const surfaceContainerLow = Color(0xFFF4F3FA);
  static const surfaceContainer = Color(0xFFEEEEF7);
  static const surfaceContainerHigh = Color(0xFFE8E7F1);
  static const surfaceContainerHighest = Color(0xFFE2E1EC);

  // Utility
  static const outline = Color(0xFF767680);
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final educatorDetailProvider =
    FutureProvider.family.autoDispose<Educator, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/educators/$id');
  final data = response.data;
  Map<String, dynamic> educatorData = {};
  if (data is Map && data['data'] is Map && data['data']['educator'] != null) {
    educatorData = Map<String, dynamic>.from(data['data']['educator']);
  } else if (data is Map && data['educator'] != null) {
    educatorData = Map<String, dynamic>.from(data['educator']);
  } else if (data is Map) {
    educatorData = Map<String, dynamic>.from(data);
  }
  return Educator.fromJson(educatorData);
});

final educatorCoursesProvider =
    FutureProvider.family.autoDispose<List<Course>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/courses/educator/$id');
  final data = response.data;
  List<dynamic> coursesList = [];
  if (data is Map && data['data'] is Map && data['data']['courses'] != null) {
    coursesList = data['data']['courses'] as List;
  } else if (data is Map && data['courses'] != null) {
    coursesList = data['courses'] as List;
  } else if (data is List) {
    coursesList = data;
  }
  final courses = coursesList.map((e) => Course.fromJson(e)).toList();
  final hasReviewsField = coursesList.any(
    (entry) => entry is Map && entry.containsKey('reviews'),
  );
  if (courses.isEmpty || hasReviewsField) {
    return courses;
  }

  final detailedCourses = await Future.wait(
    courses.map((course) async {
      final detailResponse = await api.get('/api/courses/${course.id}');
      final detailData = detailResponse.data;
      Map<String, dynamic> courseData = {};
      if (detailData is Map && detailData['data'] is Map) {
        courseData = Map<String, dynamic>.from(detailData['data']);
      } else if (detailData is Map && detailData['course'] != null) {
        courseData = Map<String, dynamic>.from(detailData['course']);
      } else if (detailData is Map) {
        courseData = Map<String, dynamic>.from(detailData);
      }
      return Course.fromJson(courseData);
    }),
  );

  return detailedCourses;
});

final educatorTestSeriesProvider = FutureProvider.family
    .autoDispose<List<TestSeries>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/test-series/educator/$id');
  final data = response.data;
  List<dynamic> list = [];
  if (data is Map && data['testSeries'] != null) {
    list = data['testSeries'] as List;
  } else if (data is List) {
    list = data;
  }
  return list.map((e) => TestSeries.fromJson(e)).toList();
});

final educatorWebinarsProvider =
    FutureProvider.family.autoDispose<List<dynamic>, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/webinars/educator/$id');
  final data = response.data;
  List<dynamic> list = [];
  if (data is Map && data['data'] is Map && data['data']['webinars'] != null) {
    list = data['data']['webinars'] as List;
  } else if (data is Map && data['webinars'] != null) {
    list = data['webinars'] as List;
  } else if (data is List) {
    list = data;
  }
  return list;
});

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────

class EducatorProfileScreen extends ConsumerWidget {
  final String educatorId;
  const EducatorProfileScreen({super.key, required this.educatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educatorAsync = ref.watch(educatorDetailProvider(educatorId));

    return educatorAsync.when(
      loading: () => const Scaffold(
        backgroundColor: _EduColors.background,
        body: Center(
          child: CircularProgressIndicator(color: _EduColors.primary),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: _EduColors.background,
        appBar: AppBar(
          backgroundColor: _EduColors.surface,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_rounded, color: _EduColors.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(educatorDetailProvider(educatorId)),
        ),
      ),
      data: (educator) => _EducatorProfileBody(
        educator: educator,
        educatorId: educatorId,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE BODY
// ─────────────────────────────────────────────

class _EducatorProfileBody extends ConsumerStatefulWidget {
  final Educator educator;
  final String educatorId;

  const _EducatorProfileBody({
    required this.educator,
    required this.educatorId,
  });

  @override
  ConsumerState<_EducatorProfileBody> createState() =>
      _EducatorProfileBodyState();
}

class _EducatorProfileBodyState extends ConsumerState<_EducatorProfileBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;
  bool _isFollowingInitialized = false;
  bool _bioExpanded = false;
  int _myRating = 0;
  int _followerCount = 0;
  VideoPlayerController? _videoController;
  WebViewController? _vimeoController;
  bool _isVideoReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _followerCount = widget.educator.followerCount;
    _initIntroVideo(widget.educator);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _EducatorProfileBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.educatorId != widget.educatorId) {
      _isFollowingInitialized = false;
      _isFollowing = false;
    }
    if (oldWidget.educator.introVideoLink != widget.educator.introVideoLink) {
      _initIntroVideo(widget.educator);
    }
    if (oldWidget.educator.followerCount != widget.educator.followerCount) {
      _followerCount = widget.educator.followerCount;
    }
  }

  bool? _computeIsFollowing(AuthState authState) {
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) return null;
    final fromEducator = widget.educator.followerIds.contains(studentId);
    final fromStudent =
        authState.student?.followingEducators.contains(widget.educator.id) ??
            false;
    return fromEducator || fromStudent;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final computedIsFollowing = _computeIsFollowing(authState) ?? false;
    final isFollowing =
        _isFollowingInitialized ? _isFollowing : computedIsFollowing;

    final educator = widget.educator;
    final educatorName =
        educator.displayName.isNotEmpty ? educator.displayName : 'Educator';
    final subjectChips = _buildSubjectChips(educator);
    final coursesAsync = ref.watch(educatorCoursesProvider(widget.educatorId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _EduColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Frosted Top App Bar ──
            SliverAppBar(
              pinned: true,
              floating: false,
              elevation: 0,
              backgroundColor: _EduColors.surface,
              surfaceTintColor: Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: _IconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                ),
              ),
              title: const Text(
                'Educator Profile',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _EduColors.onSurface,
                ),
              ),
              centerTitle: false,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _IconButton(
                    icon: Icons.share_rounded,
                    onTap: _shareProfile,
                  ),
                ),
              ],
            ),

            // ── Profile Header Card ──
            SliverToBoxAdapter(
              child: _ProfileHeaderCard(
                educator: educator,
                isFollowing: isFollowing,
                onFollowTap: _toggleFollow,
              ),
            ),

            // ── Bento Stats Grid ──
            SliverToBoxAdapter(
              child: _BentoStatsGrid(
                educator: educator,
                educatorId: widget.educatorId,
                followerCount: _followerCount,
              ),
            ),

            // ── Book 1:1 Session ──
            SliverToBoxAdapter(
              child: _BookSessionCard(educator: educator),
            ),

            // ── Intro Video ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _buildIntroVideo(educator),
              ),
            ),

            // ── About Section ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _AboutSection(
                  bio: educator.bio ?? '',
                  subjects: subjectChips,
                  experience: educator.displayExperience,
                  expanded: _bioExpanded,
                  onToggle: () => setState(() => _bioExpanded = !_bioExpanded),
                ),
              ),
            ),

            // ── Background (Experience + Qualifications) ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _BackgroundSection(
                  qualifications: educator.qualifications,
                  workExperience: educator.workExperience,
                ),
              ),
            ),

            // ── Rating + Reviews ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _RatingAndReviewsSection(
                  educator: educator,
                  coursesAsync: coursesAsync,
                  myRating: _myRating,
                  onRate: _submitRating,
                ),
              ),
            ),

            // ── Tab Bar ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: _EduColors.primary,
                  unselectedLabelColor: _EduColors.onSurfaceVariant,
                  indicatorColor: _EduColors.primary,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: _EduColors.surfaceContainerHigh,
                  labelStyle: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
            controller: _tabController,
            children: [
              _CoursesTab(
                  educatorId: widget.educatorId, educatorName: educatorName),
              _WebinarsTab(
                  educatorId: widget.educatorId, educatorName: educatorName),
              _TestSeriesTab(
                  educatorId: widget.educatorId, educatorName: educatorName),
            ],
          ),
        ),
      ),
    );
  }

  void _shareProfile() {
    // Share educator profile link
  }

  Future<void> _toggleFollow() async {
    final authState = ref.read(authStateProvider);
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a student to follow.')),
      );
      return;
    }

    final api = ApiService();
    final wasFollowing = _isFollowingInitialized
        ? _isFollowing
        : _computeIsFollowing(authState) ?? false;
    final previousCount = _followerCount;
    if (mounted) {
      setState(() {
        _isFollowingInitialized = true;
        _isFollowing = !wasFollowing;
        _followerCount = _clampFollowerCount(
          wasFollowing ? previousCount - 1 : previousCount + 1,
        );
      });
    }
    try {
      Response response;
      if (wasFollowing) {
        response = await api.delete(
          '/api/students/$studentId/unfollow',
          data: {'educatorId': widget.educatorId},
        );
      } else {
        response = await api.post(
          '/api/students/$studentId/follow',
          data: {'educatorId': widget.educatorId},
        );
      }

      final latestCount = _extractFollowerCount(response.data);
      if (latestCount != null && mounted) {
        setState(() {
          _followerCount = latestCount;
        });
      }
    } catch (e) {
      if (e is DioException) {
        final message = _extractErrorMessage(e.response?.data);
        if (wasFollowing && message.contains('not following')) {
          if (mounted) {
            setState(() {
              _isFollowing = false;
              _followerCount = previousCount;
            });
          }
          return;
        }
        if (!wasFollowing && message.contains('already following')) {
          if (mounted) {
            setState(() {
              _isFollowing = true;
              _followerCount = previousCount;
            });
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followerCount = previousCount;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    }
  }

  int _clampFollowerCount(int value) {
    if (value < 0) return 0;
    return value;
  }

  int? _extractFollowerCount(dynamic data) {
    if (data is Map && data['data'] is Map) {
      final count = data['data']['followerCount'];
      if (count is int) return count;
      if (count is num) return count.toInt();
    }
    return null;
  }

  String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final message = data['message'];
      if (message is String) return message.toLowerCase();
    }
    return '';
  }

  Future<void> _submitRating(int rating) async {
    final authState = ref.read(authStateProvider);
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in as a student to rate.')),
      );
      return;
    }

    final api = ApiService();
    try {
      await api.post(
        '/api/educators/${widget.educatorId}/rating',
        data: {'studentId': studentId, 'rating': rating},
      );

      if (mounted) {
        setState(() {
          _myRating = rating;
        });
      }
    } catch (e) {
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('You can not rate without enrolled in any Activity'),
            ),
          );
          return;
        }
        final data = e.response?.data;
        final message = data is Map ? data['message']?.toString() : null;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $e')),
      );
    }
  }

  Future<void> _initIntroVideo(Educator educator) async {
    final introUrl = _resolveUrl(educator.introVideoLink ?? '');
    if (introUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _isVideoReady = false;
          _vimeoController = null;
        });
      }
      return;
    }

    if (_isVimeoUrl(introUrl)) {
      _initVimeoController(_resolveVimeoEmbedUrl(introUrl));
      if (mounted) {
        setState(() {
          _isVideoReady = false;
        });
      }
      return;
    }

    if (_videoController != null && _videoController!.dataSource == introUrl) {
      return;
    }

    await _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(introUrl));
    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoReady = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVideoReady = false;
        });
      }
    }
  }

  void _initVimeoController(String embedUrl) {
    if (embedUrl.isEmpty) return;
    _vimeoController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(embedUrl));
  }

  Widget _buildIntroVideo(Educator educator) {
    final resolvedVideoUrl = _resolveUrl(educator.introVideoLink ?? '');

    if (resolvedVideoUrl.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _EduColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.play_circle_outline, color: _EduColors.primary),
            SizedBox(width: 12),
            Expanded(
              child: Text('Intro video not available for this educator.'),
            ),
          ],
        ),
      );
    }

    final vimeoEmbedUrl = _resolveVimeoEmbedUrl(resolvedVideoUrl);
    if (vimeoEmbedUrl.isNotEmpty && _vimeoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: WebViewWidget(controller: _vimeoController!),
        ),
      );
    }

    final controller = _videoController;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: _isVideoReady && controller != null
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                : _videoFallback(),
          ),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          IconButton(
            onPressed: () {
              if (controller == null) return;
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            icon: CircleAvatar(
              radius: 28,
              backgroundColor: _EduColors.primary,
              child: Icon(
                controller != null && controller.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoFallback() {
    return Container(
      height: 200,
      width: double.infinity,
      color: _EduColors.surfaceContainerHigh,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_fill,
        color: _EduColors.primary,
        size: 56,
      ),
    );
  }

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    if (url.startsWith('/')) {
      return '${AppConfig.baseUrl}$url';
    }
    return '${AppConfig.baseUrl}/$url';
  }

  bool _isVimeoUrl(String url) {
    return url.contains('vimeo.com') || url.contains('player.vimeo.com');
  }

  String _resolveVimeoEmbedUrl(String url) {
    final resolved = _resolveUrl(url);
    if (resolved.contains('player.vimeo.com')) return resolved;

    final match = RegExp(r'(\d{6,})').firstMatch(resolved);
    final videoId = match?.group(1);
    if (videoId == null || videoId.isEmpty) return '';

    return 'https://player.vimeo.com/video/$videoId?playsinline=1&autoplay=0';
  }

  List<String> _buildSubjectChips(Educator educator) {
    final chips = <String>[];
    chips.addAll(educator.specialization.map(_titleCaseValue));
    chips.addAll(educator.subject.map(_titleCaseValue));
    return chips.where((value) => value.isNotEmpty).toSet().toList();
  }

  String _titleCaseValue(String value) {
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ')
        .trim();
  }
}

class _RatingAndReviewsSection extends StatelessWidget {
  final Educator educator;
  final AsyncValue<List<Course>> coursesAsync;
  final int myRating;
  final ValueChanged<int> onRate;

  const _RatingAndReviewsSection({
    required this.educator,
    required this.coursesAsync,
    required this.myRating,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final average = educator.rating?.average ?? 0;
    final count = educator.rating?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Ratings & Reviews',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _EduColors.onSurface,
              ),
            ),
            const Spacer(),
            _RatingSummary(average: average, count: count),
          ],
        ),
        const SizedBox(height: 12),
        _RatingInputRow(myRating: myRating, onRate: onRate),
        const SizedBox(height: 16),
        coursesAsync.when(
          loading: () => const _ReviewLoadingPlaceholder(),
          error: (e, _) => _ReviewEmptyState(
            message: 'Failed to load reviews',
            subtitle: e.toString(),
          ),
          data: (courses) {
            final reviews = _aggregateCourseReviews(courses);
            if (reviews.isEmpty) {
              return const _ReviewEmptyState(
                message: 'No reviews yet',
                subtitle: 'Reviews will appear after students rate courses.',
              );
            }

            final visible = reviews.take(4).toList();
            return Column(
              children: visible.map((review) => _ReviewCard(review)).toList(),
            );
          },
        ),
      ],
    );
  }

  List<_AggregatedReview> _aggregateCourseReviews(List<Course> courses) {
    final aggregated = <_AggregatedReview>[];
    for (final course in courses) {
      for (final review in course.reviews) {
        if ((review.comment ?? '').trim().isEmpty) continue;
        aggregated.add(
          _AggregatedReview(
            courseTitle: course.title,
            name: review.name ?? 'Student',
            avatar: review.avatar,
            rating: review.rating ?? 0,
            comment: review.comment ?? '',
            updatedAt: review.updatedAt ?? review.createdAt,
          ),
        );
      }
    }

    aggregated.sort(
      (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
        a.updatedAt ?? DateTime(0),
      ),
    );
    return aggregated;
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;

  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: _EduColors.tertiary, size: 18),
        const SizedBox(width: 4),
        Text(
          average.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _EduColors.onSurface,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: const TextStyle(
            fontSize: 12,
            color: _EduColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RatingInputRow extends StatelessWidget {
  final int myRating;
  final ValueChanged<int> onRate;

  const _RatingInputRow({required this.myRating, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Your Rating',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _EduColors.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (index) {
          final value = index + 1;
          final filled = value <= myRating;
          return IconButton(
            onPressed: () => onRate(value),
            icon: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? _EduColors.tertiary : _EduColors.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          );
        }),
      ],
    );
  }
}

class _ReviewLoadingPlaceholder extends StatelessWidget {
  const _ReviewLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        ShimmerCard(height: 84),
        SizedBox(height: 12),
        ShimmerCard(height: 84),
      ],
    );
  }
}

class _ReviewEmptyState extends StatelessWidget {
  final String message;
  final String subtitle;

  const _ReviewEmptyState({required this.message, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _EduColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: _EduColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AggregatedReview {
  final String courseTitle;
  final String name;
  final String? avatar;
  final double rating;
  final String comment;
  final DateTime? updatedAt;

  _AggregatedReview({
    required this.courseTitle,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.comment,
    required this.updatedAt,
  });
}

class _ReviewCard extends StatelessWidget {
  final _AggregatedReview review;

  const _ReviewCard(this.review);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.04),
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
            backgroundImage: review.avatar != null && review.avatar!.isNotEmpty
                ? NetworkImage(review.avatar!)
                : null,
            backgroundColor: _EduColors.surfaceContainerHigh,
            child: review.avatar == null || review.avatar!.isEmpty
                ? Text(
                    review.name.isNotEmpty
                        ? review.name.substring(0, 1).toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _EduColors.onSurface,
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
                      child: Text(
                        review.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _EduColors.onSurface,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: _EduColors.tertiary,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _EduColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.courseTitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _EduColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _EduColors.onSurfaceVariant,
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

// ─────────────────────────────────────────────
// PROFILE HEADER CARD
// ─────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final Educator educator;
  final bool isFollowing;
  final VoidCallback onFollowTap;

  const _ProfileHeaderCard({
    required this.educator,
    required this.isFollowing,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        educator.displayName.isNotEmpty ? educator.displayName : 'Educator';
    final handle = displayName.isNotEmpty
        ? '@${displayName.toLowerCase().replaceAll(' ', '_')}'
        : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with rating badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _EduColors.surfaceContainerHigh,
                    width: 3,
                  ),
                ),
                child: UserAvatar(
                  imageUrl: educator.imageUrl,
                  name: educator.displayName,
                  size: 88,
                  showBorder: false,
                ),
              ),
              // Rating badge
              Positioned(
                bottom: 0,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _EduColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _EduColors.primary.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 11),
                      const SizedBox(width: 2),
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

          // Name
          Text(
            displayName,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _EduColors.onSurface,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Handle
          if (handle.isNotEmpty)
            Text(
              handle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _EduColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 18),

          // Follow + Message buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FollowButton(
                isFollowing: isFollowing,
                onTap: onFollowTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 11),
        decoration: BoxDecoration(
          color: isFollowing ? _EduColors.primaryContainer : _EduColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isFollowing
              ? []
              : [
                  BoxShadow(
                    color: _EduColors.primary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isFollowing
                ? _EduColors.onPrimaryContainer
                : _EduColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _EduColors.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 16, color: _EduColors.onSurfaceVariant),
          SizedBox(width: 6),
          Text(
            'Message',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _EduColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BENTO STATS GRID
// ─────────────────────────────────────────────

class _BentoStatsGrid extends ConsumerWidget {
  final Educator educator;
  final String educatorId;
  final int? followerCount;

  const _BentoStatsGrid({
    required this.educator,
    required this.educatorId,
    this.followerCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(educatorCoursesProvider(educatorId));
    final tsAsync = ref.watch(educatorTestSeriesProvider(educatorId));
    final webinarsAsync = ref.watch(educatorWebinarsProvider(educatorId));

    final courseCount = coursesAsync.maybeWhen(
      data: (c) => c.length,
      orElse: () => 0,
    );
    final tsCount = tsAsync.maybeWhen(
      data: (t) => t.length,
      orElse: () => 0,
    );
    final webinarCount = webinarsAsync.maybeWhen(
      data: (w) => w.length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.1,
        children: [
          _BentoStatCard(
            iconData: Icons.menu_book_rounded,
            iconColor: _EduColors.primary,
            iconBg: _EduColors.primaryContainer,
            value: '$courseCount',
            label: 'Courses',
            valueColor: _EduColors.primary,
          ),
          _BentoStatCard(
            iconData: Icons.description_rounded,
            iconColor: _EduColors.secondary,
            iconBg: _EduColors.secondaryContainer,
            value: '$tsCount',
            label: 'Test Series',
            valueColor: _EduColors.secondary,
          ),
          _BentoStatCard(
            iconData: Icons.podcasts_rounded,
            iconColor: _EduColors.tertiary,
            iconBg: _EduColors.tertiaryContainer,
            value: '$webinarCount',
            label: 'Webinars',
            valueColor: _EduColors.tertiary,
          ),
          _BentoStatCard(
            iconData: Icons.people_alt_rounded,
            iconColor: _EduColors.onSurfaceVariant,
            iconBg: _EduColors.surfaceContainerHighest,
            value: _formatCount(followerCount ?? educator.followerCount),
            label: 'Followers',
            valueColor: _EduColors.onSurface,
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

class _BentoStatCard extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final Color valueColor;

  const _BentoStatCard({
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _EduColors.onSurfaceVariant,
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

// ─────────────────────────────────────────────
// BOOK SESSION CARD
// ─────────────────────────────────────────────

class _BookSessionCard extends StatelessWidget {
  final Educator educator;

  const _BookSessionCard({required this.educator});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: const BorderSide(color: _EduColors.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.05),
            blurRadius: 12,
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
                const Text(
                  'Book 1:1 Session',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _EduColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: '₹800 ',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: _EduColors.primary,
                        ),
                      ),
                      TextSpan(
                        text: '/ hour',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _EduColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              // Handle book session
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _EduColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: _EduColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ABOUT SECTION
// ─────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  final String bio;
  final List<String> subjects;
  final String experience;
  final bool expanded;
  final VoidCallback onToggle;

  const _AboutSection({
    required this.bio,
    required this.subjects,
    required this.experience,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedBio = bio.trim();
    final hasBio = trimmedBio.isNotEmpty;
    final isLong = trimmedBio.length > 180;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'About Me',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _EduColors.onSurface,
                ),
              ),
              const Spacer(),
              if (experience.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _EduColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$experience Exp',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: _EduColors.tertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Bio card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _EduColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBio
                      ? (expanded || !isLong
                          ? trimmedBio
                          : '${trimmedBio.substring(0, 180)}...')
                      : 'No bio added yet.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: _EduColors.onSurfaceVariant,
                    height: 1.65,
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
                        color: _EduColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (subjects.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subjects.asMap().entries.map((entry) {
                      final isFirst = entry.key == 0;
                      return _SubjectChip(
                        label: entry.value,
                        bg: isFirst
                            ? _EduColors.primaryContainer
                            : _EduColors.secondaryContainer,
                        fg: isFirst
                            ? _EduColors.primary
                            : _EduColors.onSecondaryContainer,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _SubjectChip({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BACKGROUND SECTION (Qualifications)
// ─────────────────────────────────────────────

class _BackgroundSection extends StatelessWidget {
  final List<Qualification> qualifications;
  final List<WorkExperience> workExperience;
  const _BackgroundSection({
    required this.qualifications,
    required this.workExperience,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Background',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: _EduColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (workExperience.isEmpty && qualifications.isEmpty)
            const _EmptyCardPlaceholder(
              message: 'No background details added yet',
            ),
          ...workExperience.map((w) => _BackgroundTile(
                qual: Qualification(
                  title: w.title ?? 'Experience',
                  institution: w.company ?? '',
                  year: w.duration,
                ),
                isExperience: true,
              )),
          ...qualifications.map((q) => _BackgroundTile(qual: q)),
        ],
      ),
    );
  }
}

class _BackgroundTile extends StatelessWidget {
  final Qualification qual;
  final bool isExperience;
  const _BackgroundTile({required this.qual, this.isExperience = false});

  @override
  Widget build(BuildContext context) {
    final isDegree = qual.degree != null && !isExperience;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _EduColors.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDegree ? Icons.school_rounded : Icons.work_rounded,
              color: isDegree ? _EduColors.tertiary : _EduColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qual.title ?? qual.degree ?? 'Qualification',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _EduColors.onSurface,
                  ),
                ),
                if (qual.institution != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    qual.institution!,
                    style: const TextStyle(
                        fontSize: 12, color: _EduColors.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (qual.year != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _EduColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                qual.year!,
                style: const TextStyle(
                  fontSize: 11,
                  color: _EduColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB VIEWS
// ─────────────────────────────────────────────

class _CoursesTab extends ConsumerWidget {
  final String educatorId;
  final String educatorName;
  const _CoursesTab({
    required this.educatorId,
    required this.educatorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(educatorCoursesProvider(educatorId));

    return coursesAsync.when(
      loading: () => const _LoadingGrid(),
      error: (e, _) => const _EmptyState(
        emoji: '📚',
        message: 'Failed to load courses',
        subtitle: 'Please try again later',
      ),
      data: (courses) {
        final otooCourses = courses
            .where((c) => c.courseType == 'one-to-one' || c.courseType == 'OTO')
            .toList();
        final otaCourses = courses
            .where((c) => c.courseType == 'one-to-all' || c.courseType == 'OTA')
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            if (otooCourses.isNotEmpty) ...[
              _TabSectionHeader(
                title: 'One to One Live',
                subtitle: 'Personalized sessions for focused learning',
                onSeeAll: () {},
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: otooCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _CourseCardHorizontal(course: otooCourses[i]),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (otaCourses.isNotEmpty) ...[
              _TabSectionHeader(
                title: 'One to All Live',
                subtitle: 'Interactive group learning classes',
                onSeeAll: () {},
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 230,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: otaCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) =>
                      _CourseCardHorizontal(course: otaCourses[i]),
                ),
              ),
            ],
            if (otooCourses.isEmpty && otaCourses.isEmpty)
              const _EmptyState(
                emoji: '📚',
                message: 'No courses yet',
                subtitle: 'Check back later for new courses',
              ),
          ],
        );
      },
    );
  }
}

class _WebinarsTab extends ConsumerWidget {
  final String educatorId;
  final String educatorName;
  const _WebinarsTab({required this.educatorId, required this.educatorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final webinarsAsync = ref.watch(educatorWebinarsProvider(educatorId));

    return webinarsAsync.when(
      loading: () => const _LoadingGrid(),
      error: (e, _) => const _EmptyState(
        emoji: '📅',
        message: 'Failed to load webinars',
        subtitle: 'Please try again later',
      ),
      data: (webinars) {
        if (webinars.isEmpty) {
          return const _EmptyState(
            emoji: '📅',
            message: 'No webinars yet',
            subtitle: 'Join live and upcoming webinars',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _TabSectionHeader(
              title: 'Webinars by $educatorName',
              subtitle: 'Join live and upcoming sessions',
              onSeeAll: () {},
            ),
            const SizedBox(height: 14),
            ...webinars.take(6).map((w) => _WebinarCard(webinar: w)),
          ],
        );
      },
    );
  }
}

class _TestSeriesTab extends ConsumerWidget {
  final String educatorId;
  final String educatorName;
  const _TestSeriesTab({required this.educatorId, required this.educatorName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tsAsync = ref.watch(educatorTestSeriesProvider(educatorId));

    return tsAsync.when(
      loading: () => const _LoadingGrid(),
      error: (e, _) => const _EmptyState(
        emoji: '📝',
        message: 'Failed to load test series',
        subtitle: 'Please try again later',
      ),
      data: (testSeries) {
        if (testSeries.isEmpty) {
          return const _EmptyState(
            emoji: '📝',
            message: 'No test series yet',
            subtitle: 'Practice with comprehensive test series',
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            _TabSectionHeader(
              title: 'Test Series by $educatorName',
              subtitle: 'Practice with curated test series',
              onSeeAll: () {},
            ),
            const SizedBox(height: 14),
            ...testSeries.take(6).map((ts) => _TestSeriesCard(testSeries: ts)),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// TAB SECTION HEADER
// ─────────────────────────────────────────────

class _TabSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSeeAll;

  const _TabSectionHeader({
    required this.title,
    required this.subtitle,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _EduColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                    fontSize: 12, color: _EduColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See All',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _EduColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// CARDS
// ─────────────────────────────────────────────

/// Horizontal scrollable course card (like HTML design)
class _CourseCardHorizontal extends StatelessWidget {
  final Course course;
  const _CourseCardHorizontal({required this.course});

  @override
  Widget build(BuildContext context) {
    final isOTO =
        course.courseType == 'one-to-one' || course.courseType == 'OTO';

    return GestureDetector(
      onTap: () => context.push('/course/${course.id}'),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: _EduColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF282B51).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    course.imageUrl.isNotEmpty
                        ? Image.network(course.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _CourseThumbnailPlaceholder())
                        : _CourseThumbnailPlaceholder(),
                    // LIVE badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _EduColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _EduColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: _EduColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        course.subject.take(1).join(', '),
                        style: const TextStyle(
                            fontSize: 11, color: _EduColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      PriceWidget(
                        price: course.finalPrice,
                        originalPrice: course.fees,
                        discount: course.discount,
                        fontSize: 14,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _EduColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Enroll',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
    );
  }
}

class _WebinarCard extends StatelessWidget {
  final dynamic webinar;
  const _WebinarCard({required this.webinar});

  @override
  Widget build(BuildContext context) {
    final title = webinar['title'] ?? 'Webinar';
    final description = webinar['description'] ?? '';
    final date = webinar['scheduledAt'] ?? webinar['date'] ?? '';
    final imageUrl = webinar['imageUrl'] ?? webinar['thumbnail'] ?? '';
    final id = webinar['_id'] ?? webinar['id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/webinar/$id'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _WebinarThumbnailPlaceholder())
                      : _WebinarThumbnailPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(
                      label: 'Webinar',
                      bg: const Color(0xFFFFF3E0),
                      fg: const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _EduColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: const TextStyle(
                            fontSize: 12, color: _EduColors.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 11, color: _EduColors.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                                fontSize: 11,
                                color: _EduColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _EduColors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _TestSeriesCard extends StatelessWidget {
  final TestSeries testSeries;
  const _TestSeriesCard({required this.testSeries});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF282B51).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/test-series/${testSeries.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _EduColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.assignment_rounded,
                    color: _EduColors.tertiary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TypeBadge(
                      label: 'Test Series',
                      bg: _EduColors.tertiaryContainer,
                      fg: _EduColors.tertiary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      testSeries.title,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _EduColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.quiz_outlined,
                            size: 12, color: _EduColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${testSeries.totalTests ?? 0} Tests',
                          style: const TextStyle(
                              fontSize: 12, color: _EduColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: _EduColors.outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;

  const _TypeBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _EduColors.surfaceContainerLow,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _EduColors.primary, size: 20),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String message;
  final String subtitle;
  const _EmptyState({
    required this.emoji,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _EduColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 13, color: _EduColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCardPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyCardPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: _EduColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _EduColors.surfaceContainerHighest),
      ),
      child: Center(
        child: Text(
          message,
          style:
              const TextStyle(color: _EduColors.onSurfaceVariant, fontSize: 14),
        ),
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: List.generate(4, (_) => const ShimmerCard(height: 110)),
    );
  }
}

class _CourseThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: _EduColors.primaryContainer,
      child: const Icon(Icons.play_circle_outline_rounded,
          size: 36, color: _EduColors.primary),
    );
  }
}

class _WebinarThumbnailPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF3E0),
      child: const Icon(Icons.videocam_outlined,
          size: 36, color: Color(0xFFE65100)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Profile',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _EduColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: _EduColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _EduColors.primary,
                foregroundColor: _EduColors.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STICKY TAB BAR DELEGATE
// ─────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _EduColors.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
