import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/webinar_model.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// Webinar Detail Provider
final webinarDetailProvider =
    FutureProvider.family.autoDispose<Webinar, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/webinars/$id');
  final data = response.data;

  Map<String, dynamic> webinarData = {};
  if (data is Map && data['data'] != null) {
    webinarData = Map<String, dynamic>.from(data['data']);
  } else if (data is Map && data['webinar'] != null) {
    webinarData = data['webinar'];
  } else if (data is Map) {
    webinarData = Map<String, dynamic>.from(data);
  }

  return Webinar.fromJson(webinarData);
});

class WebinarDetailsScreen extends ConsumerStatefulWidget {
  final String webinarId;

  const WebinarDetailsScreen({super.key, required this.webinarId});

  @override
  ConsumerState<WebinarDetailsScreen> createState() =>
      _WebinarDetailsScreenState();
}

class _WebinarDetailsScreenState extends ConsumerState<WebinarDetailsScreen> {
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
    final webinarAsync = ref.watch(webinarDetailProvider(widget.webinarId));

    return Scaffold(
      bottomNavigationBar: _EnrollBar(
        webinar: webinarAsync.asData?.value,
        isLoading: _isEnrolling,
        onEnroll: _startEnrollment,
      ),
      body: webinarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Scaffold(
          appBar: AppBar(),
          body: ErrorStateWidget(
            message: error.toString(),
            onRetry: () =>
                ref.invalidate(webinarDetailProvider(widget.webinarId)),
          ),
        ),
        data: (webinar) => _buildContent(context, webinar),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Webinar webinar) {
    final title = webinar.title.isNotEmpty ? webinar.title : 'Webinar Details';
    final description = webinar.description ?? '';
    final feeText =
        webinar.isFree == true ? 'Free' : '₹${(webinar.fees ?? 0).toInt()}';
    final dateText = webinar.scheduledAt != null
        ? DateFormatter.formatDate(webinar.scheduledAt!)
        : 'TBA';
    final durationText =
        webinar.duration != null ? '${webinar.duration} mins' : 'TBA';
    final subjectChip =
        webinar.subject.isNotEmpty ? webinar.subject.first.toUpperCase() : null;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 18),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined,
                  color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: const Color(0xFFE7EEFF),
                  child: webinar.imageUrl.isNotEmpty
                      ? Image.network(
                          webinar.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : const Icon(
                          Icons.videocam,
                          size: 64,
                          color: Color(0xFF9BB1E6),
                        ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.25),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      if (webinar.subject.isNotEmpty)
                        _TagChip(label: subjectChip!),
                      if (webinar.subject.length > 1) ...[
                        const SizedBox(width: 8),
                        _TagChip(label: webinar.subject[1].toUpperCase()),
                      ],
                      if (webinar.isLive) ...[
                        const SizedBox(width: 8),
                        _TagChip(label: 'LIVE', isSolid: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WebinarSummaryCard(
                  title: title,
                  description: description,
                  priceText: feeText,
                  dateText: dateText,
                  durationText: durationText,
                ),
                const SizedBox(height: 18),
                _LeadEducatorCard(webinar: webinar),
                const SizedBox(height: 18),
                _InfoSection(webinar: webinar),
                const SizedBox(height: 18),
                _ReviewPlaceholder(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WebinarSummaryCard extends StatelessWidget {
  final String title;
  final String description;
  final String priceText;
  final String dateText;
  final String durationText;

  const _WebinarSummaryCard({
    required this.title,
    required this.description,
    required this.priceText,
    required this.dateText,
    required this.durationText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1B5E).withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF182244),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Color(0xFF6B7280),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              _InfoPill(
                icon: Icons.calendar_today_rounded,
                label: dateText,
              ),
              const SizedBox(width: 10),
              _InfoPill(
                icon: Icons.access_time_rounded,
                label: durationText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadEducatorCard extends StatelessWidget {
  final Webinar webinar;

  const _LeadEducatorCard({required this.webinar});

  @override
  Widget build(BuildContext context) {
    if (webinar.educatorName == null || webinar.educatorName!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lead Educator',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182244),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (webinar.educatorId != null) {
              context.push('/educator/${webinar.educatorId}');
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                UserAvatar(
                  imageUrl: webinar.educatorImage,
                  name: webinar.educatorName,
                  size: 52,
                  showBorder: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        webinar.educatorName!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF182244),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View profile',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final Webinar webinar;

  const _InfoSection({required this.webinar});

  @override
  Widget build(BuildContext context) {
    final typeText = webinar.webinarType == 'one-to-one'
        ? 'Live 1:1 Session'
        : 'Live Interactive Session with Q&A and PDF notes';
    final formatText = webinar.duration != null
        ? 'Digital whiteboard + recorded access'
        : 'Digital presentation';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Webinar Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF182244),
          ),
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.book_rounded,
          title: 'Type',
          value: typeText,
        ),
        const SizedBox(height: 10),
        _InfoTile(
          icon: Icons.ondemand_video_rounded,
          title: 'Format',
          value: formatText,
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
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

class _ReviewPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF182244),
              ),
            ),
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                SizedBox(width: 4),
                Text('0.0 (0)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'No reviews yet',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSolid;

  const _TagChip({required this.label, this.isSolid = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isSolid ? const Color(0xFF1D4ED8) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isSolid ? Colors.white : const Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _EnrollBar extends StatelessWidget {
  final Webinar? webinar;
  final bool isLoading;
  final void Function(Webinar webinar) onEnroll;

  const _EnrollBar({
    required this.webinar,
    required this.isLoading,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    if (webinar == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : () => onEnroll(webinar!),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.event_available_rounded, size: 18),
            label: Text(
              isLoading ? 'PROCESSING' : 'ENROLL NOW',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on _WebinarDetailsScreenState {
  Future<void> _startEnrollment(Webinar webinar) async {
    final authState = ref.read(authStateProvider);
    if (!authState.isAuthenticated || !authState.isStudent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login as a student to enroll.')),
      );
      return;
    }

    final studentId = authState.student?.id;
    if (studentId == null || studentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student profile not found.')),
      );
      return;
    }

    setState(() {
      _isEnrolling = true;
    });

    try {
      final isFree = webinar.isFree == true || (webinar.fees ?? 0) <= 0;
      if (isFree) {
        await ApiService().post(
          '/api/webinars/${webinar.id}/enroll',
          data: {'studentId': studentId},
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrolled successfully.')),
        );

        ref.invalidate(webinarDetailProvider(webinar.id));
        setState(() {
          _isEnrolling = false;
        });
        return;
      }

      final response = await ApiService().post(
        '/api/payments/orders',
        data: {
          'studentId': studentId,
          'productType': 'webinar',
          'productId': webinar.id,
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
        'name': webinar.title,
        'description': 'Webinar Enrollment',
        'prefill': {
          'email': authState.user?.email ?? '',
          'contact': authState.user?.mobileNumber ?? '',
        },
        'notes': {
          'productType': 'webinar',
          'productId': webinar.id,
        },
      };

      _razorpay.open(options);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrollment failed: $error')),
      );
      setState(() {
        _isEnrolling = false;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful. Enrolled!')),
      );

      ref.invalidate(webinarDetailProvider(widget.webinarId));
      setState(() {
        _pendingIntentId = null;
        _isEnrolling = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $error')),
      );
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      _pendingIntentId = null;
      _isEnrolling = false;
    });
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
    setState(() {
      _pendingIntentId = null;
      _isEnrolling = false;
    });
  }
}
