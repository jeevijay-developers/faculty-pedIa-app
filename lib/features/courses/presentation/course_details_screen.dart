import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/course_model.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';
import '../../auth/providers/auth_provider.dart';

// Course Detail Provider
final courseDetailProvider =
    FutureProvider.family.autoDispose<Course, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/courses/$id');
  final data = response.data;

  Map<String, dynamic> courseData = {};
  if (data is Map && data['course'] != null) {
    courseData = data['course'];
  } else if (data is Map) {
    courseData = Map<String, dynamic>.from(data);
  }

  return Course.fromJson(courseData);
});

class CourseDetailsScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailsScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailsScreen> createState() =>
      _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends ConsumerState<CourseDetailsScreen> {
  late final Razorpay _razorpay;
  bool _isPaying = false;
  String? _pendingIntentId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));

    return courseAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(courseDetailProvider(widget.courseId)),
        ),
      ),
      data: (course) => Scaffold(
        body: _buildContent(context, course),
        bottomNavigationBar: _buildEnrollBar(context, course),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Course course) {
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: AppColors.grey200,
              child: course.imageUrl.isNotEmpty
                  ? Image.network(
                      course.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            onPressed: () => context.pop(),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseHeaderCard(context, course),
                const SizedBox(height: 16),
                _buildInfoTiles(context, course),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Overview'),
                const SizedBox(height: 12),
                _buildContentCard(
                  context,
                  title: 'About this Course',
                  child: Text(
                    course.description ?? 'No description available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (course.subject.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildContentCard(
                    context,
                    title: 'Subjects Covered',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: course.subject.map((subject) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            subject,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (course.classes != null && course.classes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildContentCard(
                    context,
                    title: 'Course Schedule',
                    child: Column(
                      children: course.classes!
                          .map((cls) => _buildClassItem(context, cls))
                          .toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseHeaderCard(BuildContext context, Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey200.withOpacity(0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.specialization.isNotEmpty || course.subject.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...course.specialization.map((spec) => _buildChip(spec)),
                ...course.subject.map((subject) => _buildChip(subject)),
              ],
            ),
          if (course.specialization.isNotEmpty || course.subject.isNotEmpty)
            const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: course.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          course.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        ),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.description ?? 'Learn from expert educators.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    if (course.educator != null)
                      GestureDetector(
                        onTap: () =>
                            context.push('/educator/${course.educator!.id}'),
                        child: Row(
                          children: [
                            UserAvatar(
                              imageUrl: course.educator!.profilePicture,
                              name: course.educator!.name,
                              size: 36,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.educator!.name ?? 'Educator',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Instructor',
                                  style: TextStyle(
                                    color: AppColors.grey500,
                                    fontSize: 12,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTiles(BuildContext context, Course course) {
    final feeText =
        course.fees != null ? '₹${course.finalPrice.toInt()}' : 'Free';
    final feeSubtext = course.hasDiscount && course.fees != null
        ? '₹${course.fees!.toInt()} • ${course.discount!.toInt()}% off'
        : 'Course Fee';
    final timelineText = _buildTimelineText(course);
    final enrollmentText = _buildEnrollmentText(course);
    final subjectText =
        course.subject.isNotEmpty ? course.subject.join(', ') : 'N/A';

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildInfoCard(
          title: 'Course Fee',
          value: feeText,
          subtitle: feeSubtext,
          icon: Icons.currency_rupee,
          accent: AppColors.success,
        ),
        _buildInfoCard(
          title: 'Timeline',
          value: timelineText,
          subtitle: 'Schedule',
          icon: Icons.calendar_today,
          accent: AppColors.info,
        ),
        _buildInfoCard(
          title: 'Enrollment',
          value: enrollmentText,
          subtitle: 'Students',
          icon: Icons.people,
          accent: AppColors.accent,
        ),
        _buildInfoCard(
          title: 'Subject',
          value: subjectText,
          subtitle: 'Focus area',
          icon: Icons.menu_book,
          accent: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.grey200,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _buildTimelineText(Course course) {
    final start = course.startDate != null
        ? DateFormatter.formatDate(course.startDate!)
        : 'TBA';
    final end = course.endDate != null
        ? DateFormatter.formatDate(course.endDate!)
        : 'TBA';
    if (start == 'TBA' && end == 'TBA') {
      return 'To be announced';
    }
    return '$start → $end';
  }

  String _buildEnrollmentText(Course course) {
    final enrolled = course.enrolledCount ?? 0;
    final max = course.maxStudents;
    if (max == null) return '$enrolled Enrolled';
    return '$enrolled/$max';
  }

  Widget _buildEnrollBar(BuildContext context, Course course) {
    final priceText =
        course.fees != null ? '₹${course.finalPrice.toInt()}' : 'Free';
    final originalText = course.hasDiscount && course.fees != null
        ? '₹${course.fees!.toInt()}'
        : null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.grey200)),
          boxShadow: [
            BoxShadow(
              color: AppColors.grey200.withOpacity(0.6),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  priceText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (originalText != null)
                  Text(
                    originalText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey500,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isPaying ? null : () => _startEnrollment(course),
                child: _isPaying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Enroll Now - $priceText'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startEnrollment(Course course) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || !authState.isStudent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login as a student to enroll.')),
        );
        context.push('/login');
      }
      return;
    }

    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile not found.')),
        );
      }
      return;
    }

    final isFree = course.fees == null || course.finalPrice <= 0;
    setState(() => _isPaying = true);

    try {
      if (isFree) {
        await ApiService().post(
          '/api/courses/${course.id}/enroll',
          data: {'studentId': studentId},
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enrolled successfully.')),
          );
          ref.invalidate(courseDetailProvider(widget.courseId));
        }
        if (mounted) {
          setState(() => _isPaying = false);
        }
        return;
      }

      final response = await ApiService().post(
        '/api/payments/orders',
        data: {
          'studentId': studentId,
          'productType': 'course',
          'productId': course.id,
        },
      );

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

      final options = {
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
        'notes': {
          'productType': 'course',
          'productId': course.id,
        },
      };

      _razorpay.open(options);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $error')),
        );
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ApiService().post(
        '/api/payments/verify',
        data: {
          'orderId': response.orderId,
          'paymentId': response.paymentId,
          'signature': response.signature,
          if (_pendingIntentId != null) 'intentId': _pendingIntentId,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful. Enrolled!')),
        );
        ref.invalidate(courseDetailProvider(widget.courseId));
        setState(() {
          _isPaying = false;
          _pendingIntentId = null;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $error')),
        );
        setState(() {
          _isPaying = false;
          _pendingIntentId = null;
        });
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    final message = response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _isPaying = false;
      _pendingIntentId = null;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
    setState(() {
      _isPaying = false;
      _pendingIntentId = null;
    });
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 64,
        color: AppColors.grey400,
      ),
    );
  }

  Widget _buildStatsRow(Course course) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.calendar_today,
            'Starts',
            course.startDate != null
                ? DateFormatter.formatDate(course.startDate!)
                : 'TBA',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.people,
            'Max Students',
            '${course.maxStudents ?? 'Unlimited'}',
          ),
          _buildStatDivider(),
          _buildStatItem(
            Icons.person,
            'Enrolled',
            '${course.enrolledCount ?? 0}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.grey300,
    );
  }

  Widget _buildClassItem(BuildContext context, CourseClass cls) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_arrow, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.title ?? 'Class',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (cls.scheduledAt != null)
                  Text(
                    DateFormatter.formatDateTime(cls.scheduledAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          if (cls.duration != null)
            Text(
              '${cls.duration} min',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
              ),
            ),
        ],
      ),
    );
  }
}
