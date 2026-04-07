import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/test_series_model.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../auth/providers/auth_provider.dart';

final testSeriesDetailProvider =
    FutureProvider.family.autoDispose<TestSeries, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/test-series/$id');
  final data = response.data;

  Map<String, dynamic> seriesData = {};
  if (data is Map) {
    if (data['testSeries'] is Map) {
      seriesData = Map<String, dynamic>.from(data['testSeries']);
    } else if (data['data'] is Map) {
      final nested = data['data'] as Map;
      if (nested['testSeries'] is Map) {
        seriesData = Map<String, dynamic>.from(nested['testSeries']);
      } else {
        seriesData = Map<String, dynamic>.from(nested);
      }
    } else {
      seriesData = Map<String, dynamic>.from(data);
    }
  }

  return TestSeries.fromJson(seriesData);
});

class TestSeriesDetailsScreen extends ConsumerStatefulWidget {
  final String testSeriesId;

  const TestSeriesDetailsScreen({super.key, required this.testSeriesId});

  @override
  ConsumerState<TestSeriesDetailsScreen> createState() =>
      _TestSeriesDetailsScreenState();
}

class _TestSeriesDetailsScreenState
    extends ConsumerState<TestSeriesDetailsScreen> {
  late final Razorpay _razorpay;
  bool _isEnrolling = false;
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
    final seriesAsync =
        ref.watch(testSeriesDetailProvider(widget.testSeriesId));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.grey900),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Series Details',
          style:
              TextStyle(color: AppColors.grey900, fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () =>
              ref.invalidate(testSeriesDetailProvider(widget.testSeriesId)),
        ),
        data: (series) => _buildContent(context, series),
      ),
      bottomNavigationBar: seriesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (series) => _buildEnrollBar(series),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TestSeries series) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    if (series.specialization.isNotEmpty)
                      _buildTag(series.specialization.first),
                    if (series.subject.isNotEmpty)
                      _buildTag(series.subject.first,
                          color: const Color(0xFFE8E8FF)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  series.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  series.description ??
                      'Master your preparation with comprehensive tests designed by top educators.',
                  style:
                      const TextStyle(color: AppColors.grey600, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildHeroCard(series),
          const SizedBox(height: 14),
          _buildPriceCard(series),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _buildHighlightCard(
                  icon: Icons.quiz_outlined,
                  title: 'Total Tests',
                  value: '${series.totalTests ?? 0} Full Length',
                ),
                _buildHighlightCard(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  value: 'Detailed',
                ),
                _buildHighlightCard(
                  icon: Icons.verified_outlined,
                  title: 'Validity',
                  value: '3 Months',
                ),
                _buildHighlightCard(
                  icon: Icons.emoji_events_outlined,
                  title: 'Ranking',
                  value: 'All India',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tests Included',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  'See All',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                if (series.tests != null && series.tests!.isNotEmpty)
                  ...series.tests!.take(3).map((test) => _buildTestTile(test))
                else
                  _buildEmptyTestsCard(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildReviewSection(),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Give Review and rate this Test Series',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: AppColors.primary),
              Icon(Icons.star, color: AppColors.primary),
              Icon(Icons.star, color: AppColors.primary),
              Icon(Icons.star, color: AppColors.primary),
              Icon(Icons.star, color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '5.0 / 5.0',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0F6)),
            ),
            child: const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience with this series...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE7E7FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildPriceCard(TestSeries series) {
    final originalPrice = series.fees?.toInt() ?? 0;
    final discount = series.discount ?? 0;
    final discountedPrice = discount > 0
        ? (originalPrice - (originalPrice * discount / 100)).round()
        : originalPrice;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
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
                    'LIMITED TIME OFFER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '₹$discountedPrice',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹$originalPrice',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.grey500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (discount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${discount.toInt()}% OFF',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.grey600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(Test test) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6E6F2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.science_outlined,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title ?? 'Test',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildTestInfo(
                            Icons.timer_outlined, '${test.duration ?? 0} Min'),
                        const SizedBox(width: 12),
                        _buildTestInfo(Icons.star_outline,
                            '${test.totalMarks ?? 0} Marks'),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'FREE DEMO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.warning_amber_outlined,
                  size: 14, color: AppColors.error),
              SizedBox(width: 6),
              Text(
                'NEGATIVE MARKING',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                  letterSpacing: 0.3,
                ),
              ),
              Spacer(),
              Text(
                'Start Test',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.grey500),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: AppColors.grey600),
        ),
      ],
    );
  }

  Widget _buildEmptyTestsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: const [
          Icon(Icons.assignment_outlined, size: 48, color: AppColors.grey400),
          SizedBox(height: 10),
          Text(
            'No tests available yet',
            style: TextStyle(color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  bool _isEnrolled(AuthState authState, TestSeries series) {
    if (!authState.isAuthenticated || !authState.isStudent) return false;
    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) return false;
    return series.enrolledStudentIds.contains(studentId);
  }

  Widget _buildEnrollBar(TestSeries series) {
    final authState = ref.watch(authStateProvider);
    final isEnrolled = _isEnrolled(authState, series);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F4FF),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: _isEnrolling
                ? null
                : () {
                    if (isEnrolled) {
                      context.go('/dashboard/test-series');
                    } else {
                      _startEnrollment(series);
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        isEnrolled ? 'START TEST' : 'ENROLL NOW',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(TestSeries series) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Container(
            height: 190,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              image: series.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(series.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: series.imageUrl.isEmpty
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        color: Colors.white54, size: 42),
                  )
                : null,
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.star, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '4.9 Rated',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startTest(TestSeries series) {
    final tests = series.tests ?? [];
    final firstTest = tests.firstWhere((test) => test.id.isNotEmpty,
        orElse: () => Test(id: ''));
    if (firstTest.id.isEmpty) {
      _showSnack('No tests available for this series yet.');
      return;
    }

    context.push('/live-test/${firstTest.id}');
  }

  Future<void> _startEnrollment(TestSeries series) async {
    final authState = ref.read(authStateProvider);
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
      final isFree = series.fees == null || (series.fees ?? 0) <= 0;
      if (isFree) {
        await ApiService().post(
          '/api/test-series/${series.id}/enroll',
          data: {'studentId': studentId},
        );
        if (!mounted) return;
        _showSnack('Enrolled successfully.');
        ref.invalidate(testSeriesDetailProvider(widget.testSeriesId));
        setState(() => _isEnrolling = false);
        return;
      }

      final response = await ApiService().post(
        '/api/payments/orders',
        data: {
          'studentId': studentId,
          'productType': 'testSeries',
          'productId': series.id,
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
        'name': series.title,
        'description': 'Test Series Enrollment',
        'prefill': {
          'email': authState.user?.email ?? '',
          'contact': authState.user?.mobileNumber ?? '',
        },
        'notes': {
          'productType': 'testSeries',
          'productId': series.id,
        },
      };

      _razorpay.open(options);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Enrollment failed: $error');
      setState(() => _isEnrolling = false);
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

      if (!mounted) return;
      _showSnack('Payment successful. Enrolled!');
      ref.invalidate(testSeriesDetailProvider(widget.testSeriesId));
      setState(() {
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
    final message = response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment failed. Please try again.';
    _showSnack(message);
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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ── Stat Pill ──────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.06) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : color,
            ),
          ),
        ],
      ),
    );
  }
}
