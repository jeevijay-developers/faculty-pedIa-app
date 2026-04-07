import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_config.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatter.dart';
import '../../shared/widgets/shimmer_widgets.dart';
import '../../shared/widgets/state_widgets.dart';

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

class Post {
  final String id;
  final String title;
  final String? excerpt;
  final String? content;
  final String? authorAvatarUrl;
  final String? authorName;
  final DateTime? createdAt;
  final List<String> tags;
  final List<String> specializations;

  Post({
    required this.id,
    required this.title,
    this.excerpt,
    this.content,
    this.authorAvatarUrl,
    this.authorName,
    this.createdAt,
    this.tags = const [],
    this.specializations = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    String? author;
    String? authorAvatar;
    if (json['educatorId'] is Map) {
      final educator = json['educatorId'] as Map;
      author = educator['fullName']?.toString() ??
          educator['username']?.toString() ??
          educator['name']?.toString();
      authorAvatar = educator['profilePicture']?.toString() ??
          educator['avatar']?.toString();
    } else if (json['author'] is Map) {
      author = (json['author'] as Map)['name']?.toString();
      authorAvatar = (json['author'] as Map)['avatar']?.toString() ??
          (json['author'] as Map)['image']?.toString();
    } else {
      author = json['authorName']?.toString();
      authorAvatar =
          json['authorAvatar']?.toString() ?? json['authorImage']?.toString();
    }

    final tags = (json['tags'] is List)
        ? (json['tags'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final subjects = (json['subjects'] is List)
        ? (json['subjects'] as List).map((e) => e.toString()).toList()
        : (json['subject'] is String)
            ? [json['subject'].toString()]
            : <String>[];

    final specializations = (json['specializations'] is List)
        ? (json['specializations'] as List).map((e) => e.toString()).toList()
        : (json['specialization'] is String)
            ? [json['specialization'].toString()]
            : <String>[];

    return Post(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['heading']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? json['summary']?.toString(),
      content: json['content']?.toString() ?? json['description']?.toString(),
      authorAvatarUrl: authorAvatar,
      authorName: author,
      createdAt: DateFormatter.parseDate(json['createdAt']?.toString()) ??
          DateFormatter.parseDate(json['created_at']?.toString()),
      tags: tags.isNotEmpty ? tags : subjects,
      specializations: specializations,
    );
  }
}

final postsProvider = FutureProvider.family
    .autoDispose<List<Post>, String?>((ref, examType) async {
  String? specializationForApi(String? type) {
    if (type == null || type.isEmpty) return null;
    switch (type.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      case 'upsc':
        return 'UPSC';
      default:
        return type.toUpperCase();
    }
  }

  final api = ApiService();
  final specialization = specializationForApi(examType);
  final response = await api.get(
    '/api/posts',
    queryParameters:
        specialization == null ? null : {'specialization': specialization},
  );
  final data = response.data;

  List<dynamic> list = [];
  if (data is Map) {
    if (data['posts'] is List) {
      list = data['posts'] as List;
    } else if (data['data'] is Map && (data['data'] as Map)['posts'] is List) {
      list = (data['data'] as Map)['posts'] as List;
    } else if (data['data'] is List) {
      list = data['data'] as List;
    }
  } else if (data is List) {
    list = data;
  }

  final posts = list
      .whereType<Map<String, dynamic>>()
      .map((e) => Post.fromJson(e))
      .toList();

  if (specialization == null) return posts;

  String normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  final target = normalize(specialization);
  return posts.where((post) {
    final specMatch =
        post.specializations.any((value) => normalize(value) == target);
    final tagMatch = post.tags.any((t) => normalize(t) == target);
    return specMatch || tagMatch;
  }).toList();
});

class PostsScreen extends ConsumerWidget {
  final String? examType;

  const PostsScreen({super.key, this.examType});

  String? get _examLabel {
    final type = examType;
    if (type == null || type.isEmpty) return null;
    switch (type.toLowerCase()) {
      case 'iit-jee':
        return 'IIT-JEE';
      case 'neet':
        return 'NEET';
      case 'cbse':
        return 'CBSE';
      case 'upsc':
        return 'UPSC';
      default:
        return type.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(postsProvider(examType));
    final examLabel = _examLabel;

    return Scaffold(
      backgroundColor: isDark ? kBgDark : kBgLight,
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () async => ref.invalidate(postsProvider(examType)),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context, isDark, examLabel),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                      child: Row(
                        children: [
                          const Icon(Icons.article_rounded,
                              color: kPrimary, size: 13),
                          const SizedBox(width: 6),
                          Text(
                            examLabel == null
                                ? 'All Posts'
                                : '$examLabel Posts',
                            style: const TextStyle(
                              color: kPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            postsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const _PostShimmerCard(),
                  childCount: 6,
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorStateWidget(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(postsProvider(examType)),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateWidget(
                      icon: Icons.article_outlined,
                      title: 'No posts yet',
                      subtitle: examLabel == null
                          ? 'Check back later for updates.'
                          : 'No posts for $examLabel yet.',
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _PostCard(
                      post: posts[index],
                      isDark: isDark,
                    ),
                    childCount: posts.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(
      BuildContext context, bool isDark, String? examLabel) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      backgroundColor: kPrimary,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              final type = examType;
              if (type != null && type.isNotEmpty) {
                context.go('/exam-content/$type');
              } else {
                context.go('/exams');
              }
            }
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
                        'STAY UPDATED',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        examLabel == null ? 'Latest Posts' : '$examLabel Posts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        examLabel == null
                            ? 'Announcements, tips and updates'
                            : 'Updates tailored for $examLabel',
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
                    'Posts',
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
}

class _PostCard extends StatelessWidget {
  final Post post;
  final bool isDark;

  const _PostCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final date = post.createdAt != null
        ? DateFormatter.formatRelative(post.createdAt!)
        : 'Just now';
    final examLabel = post.specializations.isNotEmpty
        ? post.specializations.first
        : (post.tags.isNotEmpty ? post.tags.first : '');
    final subtitle = post.excerpt ?? post.content ?? '';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? kText1Dark : kText1Light,
                  ),
                ),
                const SizedBox(height: 6),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? kText2Dark : kText2Light,
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _metaChip(Icons.calendar_today_rounded, date, isDark),
                    if (examLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _tag(examLabel, isDark),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white.withOpacity(0.06) : kDivLight,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _authorAvatar(isDark),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        post.authorName ?? 'Faculty Pedia',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? kText1Dark : kText1Light,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'Read More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? kText2Dark : kPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 12, color: isDark ? kText2Dark : kPrimary),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : kPrimaryMid,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isDark ? kText2Dark : kPrimary,
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : kPrimaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : kPrimaryMid,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? kText2Dark : kText2Light,
            ),
          ),
        ],
      ),
    );
  }

  Widget _authorAvatar(bool isDark) {
    final avatar = post.authorAvatarUrl;
    if (avatar != null && avatar.isNotEmpty) {
      final url = _resolveImageUrl(avatar);
      if (url.isNotEmpty) {
        return CircleAvatar(
          radius: 16,
          backgroundImage: NetworkImage(url),
          backgroundColor: isDark ? Colors.white12 : kPrimaryBg,
        );
      }
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: isDark ? Colors.white12 : kPrimaryBg,
      child: const Icon(Icons.person_rounded, size: 16, color: kPrimary),
    );
  }

  String _resolveImageUrl(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.hasScheme) return url;
    if (url.startsWith('/')) {
      return '${AppConfig.baseUrl}$url';
    }
    return '${AppConfig.baseUrl}/$url';
  }
}

class _PostShimmerCard extends StatelessWidget {
  const _PostShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppShimmer(height: 16, width: 220),
                SizedBox(height: 8),
                AppShimmer(height: 16, width: double.infinity),
                SizedBox(height: 8),
                AppShimmer(height: 12, width: double.infinity),
                SizedBox(height: 12),
                AppShimmer(height: 12, width: 120),
                SizedBox(height: 14),
                AppShimmer(height: 12, width: double.infinity),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
