import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/course_model.dart';
import '../../auth/providers/auth_provider.dart';

// ── Blue-600 palette (consistent across all screens) ──────────────────────────
const kPrimary = Color(0xFF2563EB);
const kPrimaryDark = Color(0xFF1D4ED8);
const kPrimaryLight = Color(0xFF3B82F6);
const kPrimaryBg = Color(0xFFEFF6FF);
const kPrimaryMid = Color(0xFFBFDBFE);

// ── Screen ─────────────────────────────────────────────────────────────────────
class CourseDetailsScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Future<Course> _courseFuture;
  VideoPlayerController? _videoController;
  WebViewController? _vimeoController;
  late final Razorpay _razorpay;
  String? _pendingIntentId;
  bool _isVideoReady = false;
  bool _isEnrolling = false;
  bool _isSubmittingReview = false;
  bool _descExpanded = false;

  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 0;

  // Tab controller for Features / Reviews
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _courseFuture = _fetchCourse();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _reviewController.dispose();
    _tabController.dispose();
    _vimeoController = null;
    _razorpay.clear();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<Course> _fetchCourse() async {
    final api = ApiService();
    final response = await api.get('/api/courses/${widget.courseId}');
    final data = response.data;

    Map<String, dynamic> courseData = {};
    if (data is Map && data['course'] != null) {
      courseData = Map<String, dynamic>.from(data['course']);
    } else if (data is Map) {
      courseData = Map<String, dynamic>.from(data);
    }

    final course = Course.fromJson(courseData);
    final introUrl = _resolveUrl(course.introVideo ?? '');
    if (introUrl.isNotEmpty) {
      if (_isVimeoUrl(introUrl) ||
          (course.introVideoVimeoUri ?? '').isNotEmpty) {
        _initVimeoController(
          _resolveVimeoEmbedUrl(introUrl, course.introVideoVimeoUri),
        );
      } else {
        await _initVideoController(introUrl);
      }
    }
    return course;
  }

  Future<void> _initVideoController(String url) async {
    if (_videoController != null && _videoController!.dataSource == url) return;
    await _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      if (mounted) setState(() => _isVideoReady = true);
    } catch (_) {
      if (mounted) setState(() => _isVideoReady = false);
    }
  }

  void _initVimeoController(String embedUrl) {
    if (embedUrl.isEmpty) return;
    _vimeoController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(embedUrl));
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Course>(
      future: _courseFuture,
      builder: (context, snapshot) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (snapshot.connectionState != ConnectionState.done) {
          return _loadingScaffold(isDark);
        }
        if (snapshot.hasError) {
          return _errorScaffold(snapshot.error, isDark);
        }

        final course = snapshot.data!;
        final authState = ref.watch(authStateProvider);
        final canReview = _canReviewCourse(authState, course);
        final isEnrolled = _isEnrolledCourse(authState, course);

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, course, isDark),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Tags + Title + Desc ─────────────────────────────────
                    _buildTitleSection(context, course, isDark),

                    // ── Intro Video ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildIntroVideo(course),
                    ),

                    const SizedBox(height: 24),

                    // ── Stats Row ───────────────────────────────────────────
                    _buildStatsRow(context, course, isDark),

                    const SizedBox(height: 24),

                    // ── Tab Bar ─────────────────────────────────────────────
                    _buildTabBar(isDark),

                    // ── Tab Content ─────────────────────────────────────────
                    _buildTabContent(
                        context, course, canReview, authState, isDark),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),

          // ── Bottom CTA ──────────────────────────────────────────────────
          bottomNavigationBar:
              _buildBottomBar(context, course, authState, isEnrolled, isDark),
        );
      },
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
      BuildContext context, Course course, bool isDark) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : kPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: kPrimary, size: 18),
          ),
        ),
      ),
      title: Text(
        'Course Details',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        _appBarIconBtn(Icons.share_rounded, isDark, () {}),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Divider(height: 0.5, color: Colors.grey.withOpacity(0.15)),
      ),
    );
  }

  Widget _appBarIconBtn(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : kPrimaryBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kPrimary, size: 18),
      ),
    );
  }

  // ── Title Section ──────────────────────────────────────────────────────────
  Widget _buildTitleSection(BuildContext context, Course course, bool isDark) {
    final desc = course.description ?? 'Course description not available.';
    const maxChars = 160;
    final isLong = desc.length > maxChars;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _buildTags(course),
          ),
          const SizedBox(height: 14),

          // title
          Text(
            course.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.25,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // description (collapsible)
          Text(
            _descExpanded || !isLong ? desc : '${desc.substring(0, maxChars)}…',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          if (isLong)
            GestureDetector(
              onTap: () => setState(() => _descExpanded = !_descExpanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _descExpanded ? 'Show less' : 'Read more',
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tags ───────────────────────────────────────────────────────────────────
  List<Widget> _buildTags(Course course) {
    final tags = <String>[
      ...course.specialization,
      ...course.subject,
    ];
    if (tags.isEmpty) tags.addAll(['IIT-JEE', 'NEET']);

    final tagColors = {
      'neet': [const Color(0xFFF5F3FF), const Color(0xFF7C3AED)],
      'iit-jee': [kPrimaryBg, kPrimary],
      'cbse': [const Color(0xFFECFDF5), const Color(0xFF059669)],
    };

    return tags.map((tag) {
      final entry = tagColors.entries.firstWhere(
        (e) => tag.toLowerCase().contains(e.key),
        orElse: () => MapEntry('default', [kPrimaryBg, kPrimary]),
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: entry.value[0],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: entry.value[1],
          ),
        ),
      );
    }).toList();
  }

  // ── Intro Video ────────────────────────────────────────────────────────────
  Widget _buildIntroVideo(Course course) {
    final resolvedVideoUrl = _resolveUrl(course.introVideo ?? '');
    final resolvedImageUrl = _resolveUrl(course.imageUrl);
    final vimeoEmbedUrl =
        _resolveVimeoEmbedUrl(resolvedVideoUrl, course.introVideoVimeoUri);

    if (resolvedVideoUrl.isEmpty) {
      return _videoPlaceholder(resolvedImageUrl, null);
    }

    if (vimeoEmbedUrl.isNotEmpty && _vimeoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 210,
          width: double.infinity,
          child: WebViewWidget(controller: _vimeoController!),
        ),
      );
    }

    return _videoPlaceholder(resolvedImageUrl, _videoController);
  }

  Widget _videoPlaceholder(String imageUrl, VideoPlayerController? controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 210,
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
                : imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _videoFallback())
                    : _videoFallback(),
          ),
          // dark overlay
          Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.2),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // play / pause
          GestureDetector(
            onTap: () {
              if (controller == null) return;
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimary, kPrimaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kPrimary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                controller != null && controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          // "Intro Video" label
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow(BuildContext context, Course course, bool isDark) {
    final stats = [
      _StatItem(Icons.payments_rounded, 'Fee', _formatFee(course),
          const Color(0xFF2563EB)),
      _StatItem(Icons.calendar_month_rounded, 'Timeline',
          _formatTimeline(course), const Color(0xFF7C3AED)),
      _StatItem(Icons.group_rounded, 'Enrolled', _formatEnrollment(course),
          const Color(0xFF059669)),
      _StatItem(Icons.science_rounded, 'Subject', _formatSubject(course),
          const Color(0xFFD97706)),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats
            .map((s) => Expanded(child: _StatCard(stat: s, isDark: isDark)))
            .toList(),
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kPrimary,
            borderRadius: BorderRadius.circular(11),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor:
              isDark ? Colors.white54 : const Color(0xFF64748B),
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          padding: const EdgeInsets.all(4),
          tabs: const [
            Tab(text: 'Features'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }

  // ── Tab Content ────────────────────────────────────────────────────────────
  Widget _buildTabContent(
    BuildContext context,
    Course course,
    bool canReview,
    AuthState authState,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (_, __) {
          if (_tabController.index == 0) {
            return _buildFeaturesTab(isDark);
          }
          return _buildReviewsTab(
              context, course, canReview, authState, isDark);
        },
      ),
    );
  }

  // ── Features Tab ───────────────────────────────────────────────────────────
  Widget _buildFeaturesTab(bool isDark) {
    final features = [
      _FeatureItem(Icons.live_tv_rounded, 'Interactive Live Classes',
          'Real-time doubt clearing sessions', kPrimary),
      _FeatureItem(Icons.description_rounded, 'Premium Study Material',
          'Curated notes and PDF guides', const Color(0xFF7C3AED)),
      _FeatureItem(Icons.quiz_rounded, 'Weekly Practice Tests',
          'Chapter-wise mock exams', const Color(0xFF059669)),
      _FeatureItem(Icons.headset_mic_rounded, 'Mentor Support',
          '1-on-1 doubt resolution sessions', const Color(0xFFD97706)),
      _FeatureItem(Icons.workspace_premium_rounded, 'Lifetime Access',
          'Watch anytime, anywhere', const Color(0xFFDC2626)),
    ];

    return Column(
      children: features
          .map((f) => _ModernFeatureTile(feature: f, isDark: isDark))
          .toList(),
    );
  }

  // ── Reviews Tab ────────────────────────────────────────────────────────────
  Widget _buildReviewsTab(
    BuildContext context,
    Course course,
    bool canReview,
    AuthState authState,
    bool isDark,
  ) {
    final reviews = course.reviews;
    final ratingValue = course.rating ?? 0;
    final ratingCount = course.ratingCount ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // overall rating strip
          _buildRatingStrip(ratingValue, ratingCount, isDark),
          const SizedBox(height: 16),

          // review form / enroll nudge
          if (canReview) _buildReviewForm(course, authState, isDark),
          if (!canReview) _enrollNudge(isDark),

          const SizedBox(height: 16),

          // review list
          if (reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  'No reviews yet. Be the first!',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ...reviews.map((r) => _ReviewCard(review: r, isDark: isDark)),
        ],
      ),
    );
  }

  Widget _buildRatingStrip(double rating, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count reviews',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final bar = 5 - i;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$bar',
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF94A3B8))),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          size: 11, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: bar <= rating.round()
                                ? (rating / 5).clamp(0.1, 1.0)
                                : 0.05,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? Colors.white12
                                : const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFF59E0B)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _enrollNudge(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : kPrimaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kPrimaryMid),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: kPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enroll in this course to rate and review it.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : kPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Review Form ────────────────────────────────────────────────────────────
  Widget _buildReviewForm(Course course, AuthState authState, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          // star selector
          Row(
            children: List.generate(5, (i) {
              final filled = _selectedRating >= i + 1;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // text field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'Share your thoughts about this course…',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmittingReview
                  ? null
                  : () => _submitReview(course, authState),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                disabledBackgroundColor: kPrimaryMid,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Post Review',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar(
    BuildContext context,
    Course course,
    AuthState authState,
    bool isEnrolled,
    bool isDark,
  ) {
    final isFree = course.fees == null || course.finalPrice <= 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.withOpacity(0.12), width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Enroll / Go To Course button
          Expanded(
            child: GestureDetector(
              onTap: _isEnrolling
                  ? null
                  : () async {
                      if (isEnrolled) {
                        context.go('/student-courses');
                        return;
                      }
                      await _startEnrollment(course, authState);
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [kPrimary, kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _isEnrolling
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEnrolled
                                ? Icons.play_circle_rounded
                                : Icons.school_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEnrolled
                                ? 'Go to Course'
                                : isFree
                                    ? 'Enroll Now'
                                    : 'Enroll Now  •  ₹${course.finalPrice.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading & Error Scaffolds ──────────────────────────────────────────────
  Widget _loadingScaffold(bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: kPrimary),
            const SizedBox(height: 16),
            Text(
              'Loading course…',
              style: TextStyle(
                color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorScaffold(Object? error, bool isDark) {
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFDC2626), size: 34),
              ),
              const SizedBox(height: 16),
              const Text('Failed to load course',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('$error',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => setState(() => _courseFuture = _fetchCourse()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child:
                    const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _videoFallback() => Container(
        height: 210,
        color: const Color(0xFF1E293B),
        alignment: Alignment.center,
        child: const Icon(Icons.play_circle_fill_rounded,
            color: Colors.white38, size: 56),
      );

  String _formatFee(Course course) =>
      course.fees == null ? 'Free' : '₹${course.finalPrice.toInt()}';

  String _formatTimeline(Course course) {
    final s = course.startDate != null
        ? DateFormatter.formatDate(course.startDate!)
        : 'TBA';
    final e = course.endDate != null
        ? DateFormatter.formatDate(course.endDate!)
        : 'TBA';
    return (s == 'TBA' && e == 'TBA') ? 'TBA' : '$s – $e';
  }

  String _formatEnrollment(Course course) {
    final enrolled = course.enrolledCount ?? 0;
    final max = course.maxStudents;
    return max == null ? '$enrolled' : '$enrolled/$max';
  }

  String _formatSubject(Course course) =>
      course.subject.isEmpty ? 'N/A' : course.subject.join(', ');

  String _resolveUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    return url.startsWith('/')
        ? '${AppConfig.baseUrl}$url'
        : '${AppConfig.baseUrl}/$url';
  }

  bool _isVimeoUrl(String url) =>
      url.contains('vimeo.com') || url.contains('player.vimeo.com');

  String _resolveVimeoEmbedUrl(String url, String? vimeoUri) {
    final resolved = _resolveUrl(url);
    if (resolved.contains('player.vimeo.com')) return resolved;
    final uriSource = (vimeoUri ?? '').isNotEmpty ? vimeoUri! : resolved;
    final match = RegExp(r'(\d{6,})').firstMatch(uriSource);
    final videoId = match?.group(1);
    if (videoId == null || videoId.isEmpty) return '';
    return 'https://player.vimeo.com/video/$videoId?playsinline=1&autoplay=0';
  }

  bool _canReviewCourse(AuthState authState, Course course) {
    if (!authState.isAuthenticated || !authState.isStudent) return false;
    final student = authState.student;
    if (student == null) return false;
    return student.courses.any((e) => e.courseId == course.id) ||
        course.enrolledStudentIds.contains(student.id);
  }

  bool _isEnrolledCourse(AuthState authState, Course course) {
    if (!authState.isAuthenticated || !authState.isStudent) return false;
    final student = authState.student;
    if (student == null) return false;
    return student.courses.any((e) => e.courseId == course.id) ||
        course.enrolledStudentIds.contains(student.id);
  }

  // ── Payment Handlers ───────────────────────────────────────────────────────
  Future<void> _startEnrollment(Course course, AuthState authState) async {
    if (!authState.isAuthenticated || !authState.isStudent) {
      _showSnack('Please login as a student to enroll.');
      return;
    }
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      _showSnack('Student profile not found.');
      return;
    }
    setState(() => _isEnrolling = true);
    try {
      final isFree = course.fees == null || course.finalPrice <= 0;
      if (isFree) {
        await ApiService().post('/api/courses/${course.id}/enroll',
            data: {'studentId': studentId});
        _showSnack('Enrolled successfully.');
        setState(() {
          _courseFuture = _fetchCourse();
          _isEnrolling = false;
        });
        return;
      }
      final response = await ApiService().post('/api/payments/orders', data: {
        'studentId': studentId,
        'productType': 'course',
        'productId': course.id,
      });
      final data = response.data is Map ? response.data : {};
      final orderData = data['data'] ?? data;
      final orderId = orderData['orderId'];
      final amount = orderData['amount'];
      final currency = orderData['currency'] ?? 'INR';
      final razorpayKey = orderData['razorpayKey'];
      _pendingIntentId = orderData['intentId'];
      if (orderId == null || amount == null || razorpayKey == null) {
        throw Exception('Payment order data is incomplete.');
      }
      _razorpay.open({
        'key': razorpayKey,
        'amount': amount,
        'currency': currency,
        'order_id': orderId,
        'name': course.title,
        'description': 'Course Enrollment',
        'prefill': {
          'email': authState.user?.email ?? '',
          'contact': authState.user?.mobileNumber ?? '',
        },
        'notes': {'productType': 'course', 'productId': course.id},
      });
    } catch (error) {
      _showSnack('Enrollment failed: $error');
      setState(() => _isEnrolling = false);
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService().post('/api/payments/verify', data: {
        'orderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature,
        if (_pendingIntentId != null) 'intentId': _pendingIntentId,
      });
      if (!mounted) return;
      _showSnack('Payment successful. Enrolled!');
      setState(() {
        _courseFuture = _fetchCourse();
        _pendingIntentId = null;
        _isEnrolling = false;
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack('Verification failed: $error');
      setState(() {
        _pendingIntentId = null;
        _isEnrolling = false;
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _showSnack(response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment failed. Please try again.');
    setState(() {
      _pendingIntentId = null;
      _isEnrolling = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    _showSnack('External wallet: ${response.walletName}');
    setState(() {
      _pendingIntentId = null;
      _isEnrolling = false;
    });
  }

  Future<void> _submitReview(Course course, AuthState authState) async {
    if (_selectedRating == 0) {
      _showSnack('Please select a rating.');
      return;
    }
    final comment = _reviewController.text.trim();
    if (comment.length < 3) {
      _showSnack('Please enter a review comment.');
      return;
    }
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      _showSnack('Student profile not found.');
      return;
    }
    setState(() => _isSubmittingReview = true);
    try {
      try {
        await ApiService().post('/api/courses/${course.id}/reviews', data: {
          'studentId': studentId,
          'rating': _selectedRating,
          'comment': comment,
        });
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          await ApiService().post('/api/reviews', data: {
            'studentId': studentId,
            'itemId': course.id,
            'itemType': 'course',
            'rating': _selectedRating,
            'reviewText': comment,
          });
        } else {
          rethrow;
        }
      }
      if (!mounted) return;
      _showSnack('Review submitted.');
      setState(() {
        _selectedRating = 0;
        _reviewController.clear();
        _courseFuture = _fetchCourse();
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() : null;
      _showSnack(message?.isNotEmpty == true
          ? message!
          : 'Failed to submit review: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to submit review: $error');
    } finally {
      if (mounted) setState(() => _isSubmittingReview = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1E293B),
    ));
  }
}

// ── Data models ────────────────────────────────────────────────────────────────
class _StatItem {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatItem(this.icon, this.label, this.value, this.color);
}

class _FeatureItem {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _FeatureItem(this.icon, this.title, this.subtitle, this.color);
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final bool isDark;
  const _StatCard({required this.stat, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: stat.color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            stat.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Modern Feature Tile ────────────────────────────────────────────────────────
class _ModernFeatureTile extends StatelessWidget {
  final _FeatureItem feature;
  final bool isDark;
  const _ModernFeatureTile({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: feature.color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  feature.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: feature.color, size: 20),
        ],
      ),
    );
  }
}

// ── Review Card ────────────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final CourseReview review;
  final bool isDark;
  const _ReviewCard({required this.review, required this.isDark});

  String _initial(String? name) {
    final t = (name ?? 'S').trim();
    return t.isEmpty ? 'S' : t.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: kPrimaryBg,
            backgroundImage: review.avatar != null && review.avatar!.isNotEmpty
                ? NetworkImage(review.avatar!)
                : null,
            child: review.avatar == null || review.avatar!.isEmpty
                ? Text(
                    _initial(review.name),
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w700,
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
                      child: Text(
                        review.name ?? 'Student',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // amber star pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 11, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            (review.rating ?? 0).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  review.comment ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
