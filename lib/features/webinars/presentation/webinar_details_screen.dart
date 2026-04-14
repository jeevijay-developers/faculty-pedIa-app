import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/webinar_model.dart';
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
final webinarDetailProvider =
    FutureProvider.family.autoDispose<Webinar, String>((ref, id) async {
  final api = ApiService();
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
  final response = await api.get(
    '/api/webinars/$id',
    queryParameters: studentId != null && studentId.isNotEmpty
        ? {'studentId': studentId}
        : null,
  );
  final data = response.data;

  Map<String, dynamic> webinarData = {};
  if (data is Map && data['data'] is Map) {
    final dataMap = Map<String, dynamic>.from(data['data']);
    if (dataMap['webinar'] is Map) {
      webinarData = Map<String, dynamic>.from(dataMap['webinar']);
    } else {
      webinarData = dataMap;
    }
    webinarData = _mergeWebinarExtras(webinarData, dataMap);
  } else if (data is Map && data['webinar'] is Map) {
    webinarData = Map<String, dynamic>.from(data['webinar']);
    webinarData = _mergeWebinarExtras(
      webinarData,
      Map<String, dynamic>.from(data),
    );
  } else if (data is Map) {
    webinarData = Map<String, dynamic>.from(data);
  }

  if (studentId != null && studentId.isNotEmpty) {
    final inferred = _inferIsEnrolled(webinarData, studentId);
    if (inferred != null) {
      webinarData = {
        ...webinarData,
        'isEnrolled': inferred,
      };
    } else {
      final enrolled = await _fetchStudentWebinarEnrollment(
        api,
        studentId,
        id,
      );
      if (enrolled != null) {
        webinarData = {
          ...webinarData,
          'isEnrolled': enrolled,
        };
      }
    }
  }

  return Webinar.fromJson(webinarData);
});

Map<String, dynamic> _mergeWebinarExtras(
  Map<String, dynamic> base,
  Map<String, dynamic> source,
) {
  const keys = [
    'isEnrolled',
    'enrolled',
    'isRegistered',
    'isPurchased',
    'enrolledStudents',
    'registeredStudents',
    'attendees',
    'studentEnrolled',
    'students',
    'registrations',
    'participants',
    'meetingLink',
    'webinarLink',
    'link',
  ];

  final merged = Map<String, dynamic>.from(base);
  for (final key in keys) {
    if (merged.containsKey(key)) continue;
    if (source.containsKey(key)) {
      merged[key] = source[key];
    }
  }
  return merged;
}

bool? _inferIsEnrolled(Map<String, dynamic> data, String studentId) {
  final candidateKeys = [
    'enrolledStudents',
    'registeredStudents',
    'attendees',
    'studentEnrolled',
    'students',
    'registrations',
    'participants',
  ];

  for (final key in candidateKeys) {
    final raw = data[key];
    if (raw is List) {
      return raw.any((e) => _matchesStudentId(e, studentId));
    }
  }
  return null;
}

bool _matchesStudentId(dynamic entry, String studentId) {
  if (entry is String) return entry == studentId;
  if (entry is Map) {
    final id = entry['_id'] ??
        entry['id'] ??
        entry['studentId'] ??
        (entry['student'] is Map ? entry['student']['_id'] : null);
    return id?.toString() == studentId;
  }
  return false;
}

Future<bool?> _fetchStudentWebinarEnrollment(
  ApiService api,
  String studentId,
  String webinarId,
) async {
  try {
    final response = await api.get('/api/students/$studentId');
    final data = response.data;
    Map<String, dynamic> studentData = {};
    if (data is Map && data['data'] is Map) {
      studentData = Map<String, dynamic>.from(data['data']);
    } else if (data is Map) {
      studentData = Map<String, dynamic>.from(data);
    }
    return _inferIsEnrolledFromStudent(studentData, webinarId);
  } catch (_) {
    return null;
  }
}

bool? _inferIsEnrolledFromStudent(
  Map<String, dynamic> data,
  String webinarId,
) {
  final candidateKeys = [
    'webinars',
    'enrolledWebinars',
    'registeredWebinars',
    'webinarIds',
    'webinarRegistrations',
  ];

  for (final key in candidateKeys) {
    final raw = data[key];
    if (raw is List) {
      return raw.any((e) => _matchesWebinarId(e, webinarId));
    }
  }
  return null;
}

bool _matchesWebinarId(dynamic entry, String webinarId) {
  if (entry is String) return entry == webinarId;
  if (entry is Map) {
    final id = entry['_id'] ??
        entry['id'] ??
        entry['webinarId'] ??
        (entry['webinar'] is Map ? entry['webinar']['_id'] : null);
    return id?.toString() == webinarId;
  }
  return false;
}

// ── Screen ─────────────────────────────────────────────────────────────────────
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
  bool _descExpanded = false;
  String? _pendingIntentId;
  bool _hasEnrolled = false;

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

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final webinarAsync = ref.watch(webinarDetailProvider(widget.webinarId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      appBar: AppBar(
        backgroundColor: isDark ? kBgDark : kBgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: kPrimary, size: 18),
          onPressed: () => _safePop(context),
        ),
        title: Text(
          'Webinar Details',
          style: TextStyle(
            color: isDark ? kText1Dark : kText1Light,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: kPrimary, size: 20),
              onPressed: () {},
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _buildBottomBar(context, webinarAsync.asData?.value, isDark),
      body: webinarAsync.when(
        loading: () => _loadingBody(isDark),
        error: (error, _) => _errorBody(error, isDark),
        data: (webinar) => _buildBody(context, webinar, isDark),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, Webinar webinar, bool isDark) {
    final isFree = webinar.isFree == true || (webinar.fees ?? 0) <= 0;
    final desc = webinar.description ?? '';
    const maxChars = 160;
    final isLong = desc.length > maxChars;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(webinar, isDark),
          const SizedBox(height: 16),
          _buildTitleSection(webinar, isFree, isDark),
          if (webinar.webinarType != null && webinar.webinarType!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _formatWebinarType(webinar.webinarType!),
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (webinar.educatorName != null &&
              webinar.educatorName!.isNotEmpty) ...[
            _buildEducatorCard(context, webinar, isDark),
            const SizedBox(height: 16),
          ],
          _buildInfoGrid(webinar, isFree, isDark),
          const SizedBox(height: 18),
          _sectionLabel('Webinar Information', isDark),
          const SizedBox(height: 10),
          _buildInfoTable(webinar, isDark),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _descExpanded || !isLong
                  ? desc
                  : '${desc.substring(0, maxChars)}…',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? kText2Dark : kText2Light,
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Webinar webinar, bool isDark) {
    final typeLabel = _webinarTypeChip(webinar.webinarType);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            SizedBox(
              height: 190,
              width: double.infinity,
              child: webinar.imageUrl.isNotEmpty
                  ? Image.network(
                      webinar.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _heroFallback(),
                    )
                  : _heroFallback(),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Webinar webinar, bool isFree, bool isDark) {
    final dateText = webinar.scheduledAt != null
        ? DateFormatter.formatDateTime(webinar.scheduledAt!)
        : 'TBA';
    final durationText =
        webinar.duration != null ? '${webinar.duration} hours' : 'TBA';
    final registered = webinar.registeredCount ?? 0;
    final maxSeats = webinar.maxAttendees;
    String seatsText = 'TBA';
    if (maxSeats != null) {
      final remaining = (maxSeats - registered);
      seatsText = remaining <= 0 ? 'Full' : '$remaining available';
    } else if (webinar.registeredCount != null) {
      seatsText = '${webinar.registeredCount} enrolled';
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _infoTile(
                icon: Icons.calendar_month_rounded,
                label: 'DATE',
                value: dateText,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoTile(
                icon: Icons.timer_rounded,
                label: 'DURATION',
                value: durationText,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoTile(
                icon: Icons.people_rounded,
                label: 'SEATS',
                value: seatsText,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoTile(
                icon: Icons.payments_rounded,
                label: 'PRICE',
                value: isFree ? 'Free' : '₹${(webinar.fees ?? 0).toInt()}',
                isDark: isDark,
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
  }) {
    final bgColor = highlight
        ? kPrimary
        : (isDark ? kSurfaceDark : const Color(0xFFF5F5FF));
    final textColor =
        highlight ? Colors.white : (isDark ? kText1Dark : kPrimary);
    final subColor = highlight
        ? Colors.white.withOpacity(0.9)
        : (isDark ? kText2Dark : kText2Light);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: subColor,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTable(Webinar webinar, bool isDark) {
    final subject = webinar.subject.isNotEmpty ? webinar.subject.first : '—';
    final specialization = webinar.subject.length > 1
        ? webinar.subject[1]
        : (webinar.subject.isNotEmpty ? webinar.subject.first : '—');
    final typeText = webinar.webinarType != null
        ? _formatWebinarType(webinar.webinarType!)
        : 'Live Session';
    final formatText =
        webinar.duration != null ? 'Interactive Live' : 'Live Session';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _infoColumn('SPECIALIZATION', specialization, isDark),
              ),
              Expanded(child: _infoColumn('SUBJECT', subject, isDark)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _infoColumn('TYPE', typeText, isDark)),
              Expanded(child: _infoColumn('FORMAT', formatText, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoColumn(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: kText3Light,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? kText1Dark : kText1Light,
          ),
        ),
      ],
    );
  }

  String _webinarTypeChip(String? type) {
    final t = type?.toLowerCase();
    if (t == 'one-to-one') return 'ONE TO ONE';
    if (t == 'one-to-all') return 'ONE TO ALL';
    if (t == null || t.isEmpty) return 'WEBINAR';
    return t.replaceAll('-', ' ').toUpperCase();
  }

  String _formatWebinarType(String type) {
    final t = type.toLowerCase();
    if (t == 'one-to-one') return 'Live 1:1 Session';
    if (t == 'one-to-all') return 'Live Workshop';
    return type;
  }

  // ── Sliver AppBar ─────────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(
      BuildContext context, Webinar webinar, bool isDark) {
    return SliverAppBar(
      expandedHeight: 240,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.share_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // image / gradient fallback
            webinar.imageUrl.isNotEmpty
                ? Image.network(webinar.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroFallback())
                : _heroFallback(),
            // dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            // bottom chips — subject + live status
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  ...(webinar.subject.take(2).map((s) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _HeroChip(label: s.toUpperCase()),
                      ))),
                  if (webinar.isLive) const _LiveChip(),
                ],
              ),
            ),
          ],
        ),
        title: Text(
          webinar.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
      ),
    );
  }

  // ── Title + Price ─────────────────────────────────────────────────────────
  Widget _buildTitleSection(Webinar webinar, bool isFree, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            webinar.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.25,
              color: isDark ? kText1Dark : kText1Light,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isFree ? 'Free' : '₹${(webinar.fees ?? 0).toInt()}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isFree ? const Color(0xFF16A34A) : kPrimary,
              ),
            ),
            if (!isFree)
              const Text(
                'per session',
                style: TextStyle(
                  fontSize: 10,
                  color: kText3Light,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Meta strip ────────────────────────────────────────────────────────────
  Widget _buildMetaStrip(Webinar webinar, bool isDark) {
    final dateText = webinar.scheduledAt != null
        ? DateFormatter.formatDateTime(webinar.scheduledAt!)
        : 'TBA';
    final durationText =
        webinar.duration != null ? '${webinar.duration} min' : null;

    final items = [
      _MetaItem(Icons.calendar_month_rounded, dateText),
      if (durationText != null) _MetaItem(Icons.timer_rounded, durationText),
      if (webinar.registeredCount != null && webinar.registeredCount! > 0)
        _MetaItem(Icons.people_rounded, '${webinar.registeredCount} enrolled'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kPrimaryBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryMid,
        ),
      ),
      child: Row(
        children: items.map((item) {
          final isLast = item == items.last;
          return Expanded(
            child: Row(
              children: [
                Expanded(child: _metaCell(item, isDark)),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 28,
                    color:
                        isDark ? Colors.white.withOpacity(0.08) : kPrimaryMid,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _metaCell(_MetaItem item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, size: 16, color: kPrimary),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? kText2Dark : kText2Light,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ── Educator card ─────────────────────────────────────────────────────────
  Widget _buildEducatorCard(
      BuildContext context, Webinar webinar, bool isDark) {
    return GestureDetector(
      onTap: () {
        if (webinar.educatorId != null) {
          context.push('/educator/${webinar.educatorId}');
        }
      },
      child: Container(
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
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
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
                imageUrl: webinar.educatorImage,
                name: webinar.educatorName,
                size: 50,
                showBorder: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    webinar.educatorName!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isDark ? kText1Dark : kText1Light,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'View full profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: kPrimaryBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: kPrimary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info cards ────────────────────────────────────────────────────────────
  Widget _buildInfoCards(Webinar webinar, bool isDark) {
    final typeText = webinar.webinarType == 'one-to-one'
        ? 'Live 1:1 Session'
        : 'Live Interactive Session with Q&A';
    final formatText = webinar.duration != null
        ? 'Digital whiteboard + recorded access'
        : 'Digital presentation';

    return Column(
      children: [
        _InfoCard(
          icon: Icons.book_rounded,
          label: 'TYPE',
          value: typeText,
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.ondemand_video_rounded,
          label: 'FORMAT',
          value: formatText,
          isDark: isDark,
        ),
      ],
    );
  }

  // ── Benefits ──────────────────────────────────────────────────────────────
  Widget _buildBenefits(bool isDark) {
    final benefits = [
      'Live interaction with the educator',
      'Doubt clearing session included',
      'PDF notes & study material',
      'Recording access after session',
    ];

    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: benefits.map((b) {
          final isLast = b == benefits.last;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: kPrimaryBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 13, color: kPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? kText2Dark : kText2Light,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Reviews placeholder ───────────────────────────────────────────────────
  Widget _buildReviewPlaceholder(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline_rounded, size: 20, color: kText3Light),
          const SizedBox(width: 10),
          Text(
            'No reviews yet. Be the first to review!',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: isDark ? kText1Dark : kText1Light,
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context, Webinar? webinar, bool isDark) {
    if (webinar == null) return const SizedBox.shrink();

    final isFree = webinar.isFree == true || (webinar.fees ?? 0) <= 0;
    final isEnrolled = webinar.isEnrolled == true || _hasEnrolled;
    final btnText = isEnrolled ? 'Join Now' : 'Enroll Now';
    final btnIcon = isEnrolled
        ? Icons.videocam_rounded
        : (isFree ? Icons.how_to_reg_rounded : Icons.payments_rounded);
    final btnColor = isEnrolled ? const Color(0xFF16A34A) : kPrimary;

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
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
      child: GestureDetector(
        onTap: _isEnrolling
            ? null
            : () {
                if (isEnrolled) {
                  _joinWebinar(webinar);
                } else {
                  _startEnrollment(webinar);
                }
              },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: btnColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: btnColor.withOpacity(0.35),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(btnIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      btnText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (!isEnrolled && !isFree) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '₹${(webinar.fees ?? 0).toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  // ── Loading / Error scaffolds ─────────────────────────────────────────────
  Widget _loadingBody(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: kPrimary),
          const SizedBox(height: 16),
          Text('Loading webinar…',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ],
      ),
    );
  }

  Widget _errorBody(Object error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: kPrimaryBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: kPrimary, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Failed to load webinar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: kText3Light)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () =>
                  ref.invalidate(webinarDetailProvider(widget.webinarId)),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Retry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _safePop(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ── Hero fallback ─────────────────────────────────────────────────────────
  Widget _heroFallback() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimary, kPrimaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.videocam_rounded, color: Colors.white38, size: 64),
        ),
      );

  // ── Payment handlers ──────────────────────────────────────────────────────
  Future<void> _startEnrollment(Webinar webinar) async {
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
      final isFree = webinar.isFree == true || (webinar.fees ?? 0) <= 0;

      if (isFree) {
        await ApiService().post(
          '/api/webinars/${webinar.id}/enroll',
          data: {'studentId': studentId},
        );
        if (!mounted) return;
        _showSnack('Enrolled successfully.');
        ref.invalidate(webinarDetailProvider(webinar.id));
        setState(() {
          _hasEnrolled = true;
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

      _razorpay.open({
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
      });
    } catch (error) {
      if (!mounted) return;
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
      ref.invalidate(webinarDetailProvider(widget.webinarId));
      setState(() {
        _pendingIntentId = null;
        _isEnrolling = false;
        _hasEnrolled = true;
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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1E293B),
    ));
  }

  Future<void> _joinWebinar(Webinar webinar) async {
    final link = webinar.meetingLink?.trim() ?? '';
    if (link.isEmpty) {
      _showSnack('Webinar link not available yet.');
      return;
    }
    final uri = Uri.tryParse(link);
    if (uri == null) {
      _showSnack('Invalid webinar link.');
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) _showSnack('Could not open webinar link.');
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _MetaItem {
  final IconData icon;
  final String label;
  const _MetaItem(this.icon, this.label);
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kPrimary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kText3Light,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? kText1Dark : kText1Light,
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

// ── Hero chips ─────────────────────────────────────────────────────────────────
class _HeroChip extends StatelessWidget {
  final String label;
  const _HeroChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _LiveChip extends StatefulWidget {
  const _LiveChip();

  @override
  State<_LiveChip> createState() => _LiveChipState();
}

class _LiveChipState extends State<_LiveChip>
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
    _pulse.repeat(reverse: true);
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
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (_, __) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const Text(
            'LIVE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
