import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/user_widgets.dart';
import '../../shared/models/hamburger_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../loading/skeleton.follow.dart';

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

// ── Data model ─────────────────────────────────────────────────────────────────
class _FollowingEducator {
  final String id;
  final String fullName;
  final String username;
  final String profileImage;
  final int followersCount;

  const _FollowingEducator({
    required this.id,
    required this.fullName,
    required this.username,
    required this.profileImage,
    required this.followersCount,
  });

  factory _FollowingEducator.fromJson(Map<String, dynamic> json) {
    final fullName = (json['fullName'] ?? json['name'] ?? '').toString();
    final firstName = (json['firstName'] ?? '').toString();
    final lastName = (json['lastName'] ?? '').toString();
    final name = fullName.isNotEmpty
        ? fullName
        : [firstName, lastName].where((e) => e.isNotEmpty).join(' ');

    int fCount = 0;
    for (final key in ['followerCount', 'followersCount', 'followers']) {
      final v = json[key];
      if (v is int) {
        fCount = v;
        break;
      }
      if (v is num) {
        fCount = v.toInt();
        break;
      }
      if (v is List) {
        fCount = v.length;
        break;
      }
      if (v is String) {
        fCount = int.tryParse(v) ?? 0;
        break;
      }
    }

    return _FollowingEducator(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      fullName: name,
      username: (json['username'] ?? '').toString(),
      profileImage: (json['profileImage'] ??
              json['profilePicture'] ??
              json['image'] ??
              '')
          .toString(),
      followersCount: fCount,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────
final followingEducatorsProvider =
    FutureProvider.autoDispose<List<_FollowingEducator>>((ref) async {
  final auth = ref.watch(authStateProvider);
  final studentId = auth.student?.id;
  if (!auth.isAuthenticated || studentId == null || studentId.isEmpty) {
    throw Exception('Student not authenticated');
  }

  final api = ApiService();
  final response = await api.get('/api/students/$studentId');
  final payload = response.data;

  Map<String, dynamic> sj = {};
  if (payload is Map && payload['data'] is Map) {
    sj = Map<String, dynamic>.from(payload['data']);
  } else if (payload is Map && payload['student'] is Map) {
    sj = Map<String, dynamic>.from(payload['student']);
  } else if (payload is Map) {
    sj = Map<String, dynamic>.from(payload);
  }

  final following = sj['followingEducators'];
  final list = following is List ? following : <dynamic>[];

  return list
      .map((entry) {
        if (entry is Map && entry['educatorId'] is Map) {
          return _FollowingEducator.fromJson(
              Map<String, dynamic>.from(entry['educatorId'] as Map));
        }
        if (entry is Map) {
          return _FollowingEducator.fromJson(Map<String, dynamic>.from(entry));
        }
        return const _FollowingEducator(
            id: '',
            fullName: '',
            username: '',
            profileImage: '',
            followersCount: 0);
      })
      .where((e) => e.id.isNotEmpty)
      .toList();
});

// ── Screen ─────────────────────────────────────────────────────────────────────
class FollowingTabScreen extends ConsumerStatefulWidget {
  const FollowingTabScreen({super.key});

  @override
  ConsumerState<FollowingTabScreen> createState() => _FollowingTabScreenState();
}

class _FollowingTabScreenState extends ConsumerState<FollowingTabScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final educatorsAsync = ref.watch(followingEducatorsProvider);
    final totalCount =
        educatorsAsync.maybeWhen(data: (d) => d.length, orElse: () => 0);

    if (educatorsAsync.isLoading) {
      return const FollowingTabSkeleton();
    }

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      drawer: const HamburgerDrawer(),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(followingEducatorsProvider),
        child: CustomScrollView(
          slivers: [
            // ── AppBar ──────────────────────────────────────────────────
            _buildSliverAppBar(context, isDark, totalCount),

            // ── Search ──────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: _buildSearch(isDark),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: educatorsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child:
                      Center(child: CircularProgressIndicator(color: kPrimary)),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: ErrorStateWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(followingEducatorsProvider),
                  ),
                ),
                data: (data) {
                  final q = _searchCtrl.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? data
                      : data
                          .where((e) =>
                              e.fullName.toLowerCase().contains(q) ||
                              e.username.toLowerCase().contains(q))
                          .toList();

                  if (data.isEmpty) return _emptyWidget(isDark);
                  if (filtered.isEmpty) return _noResultsWidget(isDark);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // count strip
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        child: Text(
                          '${filtered.length} educators',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? kText2Dark : kText2Light,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _FollowingCard(
                          educator: filtered[i],
                          isDark: isDark,
                          onTap: () =>
                              context.push('/educator/${filtered[i].id}'),
                          onUnfollow: () => _unfollow(context, filtered[i].id),
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
      BuildContext context, bool isDark, int totalCount) {
    return SliverAppBar(
      expandedHeight: 140,
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
            // subtle circle
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
                    'YOUR LEARNING NETWORK',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Text(
                        'Following',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Educators you follow',
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

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch(bool isDark) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? kSurfaceDark : kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _onSearchChanged,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? kText1Dark : kText1Light,
        ),
        decoration: InputDecoration(
          hintText: 'Search educators…',
          hintStyle: TextStyle(
            fontSize: 14,
            color: isDark ? kText2Dark : kText3Light,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: kPrimary, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() {});
                  },
                  child: Icon(Icons.close_rounded,
                      size: 17, color: isDark ? kText2Dark : kText3Light),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ── Empty / no results ────────────────────────────────────────────────────
  Widget _emptyWidget(bool isDark) => Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
                color: kPrimaryBg, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.people_outline_rounded,
                color: kPrimary, size: 34),
          ),
          const SizedBox(height: 16),
          const Text('Not following anyone yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Start following educators to see them here',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light),
              textAlign: TextAlign.center),
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
            child:
                const Icon(Icons.search_off_rounded, color: kPrimary, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('No results found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Try a different search',
              style: TextStyle(
                  fontSize: 13, color: isDark ? kText2Dark : kText3Light)),
        ]),
      );

  // ── Unfollow ──────────────────────────────────────────────────────────────
  Future<void> _unfollow(BuildContext context, String educatorId) async {
    final auth = ref.read(authStateProvider);
    final studentId = auth.student?.id;
    if (studentId == null || studentId.isEmpty) {
      _snack(context, 'Please log in as a student.');
      return;
    }
    // confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: isDark ? kSurfaceDark : kSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: kPrimaryBg,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.person_remove_rounded,
                      color: kPrimary, size: 26),
                ),
                const SizedBox(height: 14),
                Text('Unfollow Educator?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? kText1Dark : kText1Light,
                    )),
                const SizedBox(height: 8),
                Text(
                  'You can follow them again anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? kText2Dark : kText2Light,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : kDivLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text('Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isDark ? kText2Dark : kText2Light,
                                )),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('Unfollow',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (confirm != true) return;

    try {
      final api = ApiService();
      await api.delete(
        '/api/students/$studentId/unfollow',
        data: {'educatorId': educatorId},
      );
      ref.invalidate(followingEducatorsProvider);
      _snack(context, 'Unfollowed successfully.');
    } catch (e) {
      _snack(context, 'Failed to unfollow: $e');
    }
  }

  void _snack(BuildContext context, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFF1E293B),
    ));
  }
}

// ── Card ───────────────────────────────────────────────────────────────────────
class _FollowingCard extends StatefulWidget {
  final _FollowingEducator educator;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onUnfollow;

  const _FollowingCard({
    required this.educator,
    required this.isDark,
    required this.onTap,
    required this.onUnfollow,
  });

  @override
  State<_FollowingCard> createState() => _FollowingCardState();
}

class _FollowingCardState extends State<_FollowingCard>
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

  @override
  Widget build(BuildContext context) {
    final e = widget.educator;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Top row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // avatar with blue ring
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimary, width: 1.5),
                      ),
                      child: UserAvatar(
                        imageUrl: e.profileImage,
                        name: e.fullName,
                        size: 54,
                        showBorder: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.fullName.isNotEmpty ? e.fullName : 'Educator',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? kText1Dark : kText1Light,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          if (e.username.isNotEmpty)
                            Text(
                              '@${e.username}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? kText2Dark : kPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          // follower count chip
                        ],
                      ),
                    ),
                    // arrow
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : kPrimaryBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 13, color: kPrimary),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Divider ───────────────────────────────────────────
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.07) : kDivLight,
                ),

                const SizedBox(height: 12),

                // ── Bottom row: buttons ───────────────────────────────
                Row(
                  children: [
                    // View Profile
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: kPrimary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: kPrimary.withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'View Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Unfollow — blue outline, NOT red
                    Expanded(
                      child: GestureDetector(
                        onTap: widget.onUnfollow,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : kPrimaryBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: kPrimaryMid),
                          ),
                          child: const Center(
                            child: Text(
                              'Unfollow',
                              style: TextStyle(
                                color: kPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtCount(int c) {
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return '$c';
  }
}
