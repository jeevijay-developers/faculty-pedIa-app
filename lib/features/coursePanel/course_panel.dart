import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/test_series_model.dart';

class CoursePanelScreen extends StatefulWidget {
  final String courseId;
  final String? title;
  final String? imageUrl;

  const CoursePanelScreen({
    super.key,
    required this.courseId,
    this.title,
    this.imageUrl,
  });

  @override
  State<CoursePanelScreen> createState() => _CoursePanelScreenState();
}

class _CoursePanelScreenState extends State<CoursePanelScreen> {
  late Future<List<CourseVideo>> _videosFuture;
  late Future<List<StudyMaterialItem>> _materialsFuture;
  late Future<_CourseTestSeriesData> _testsFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _fetchVideos();
    _materialsFuture = _fetchMaterials();
    _testsFuture = _fetchTestsTabData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<List<CourseVideo>> _fetchVideos() async {
    final api = ApiService();
    dynamic data;

    try {
      final response = await api.get('/api/videos/course/${widget.courseId}');
      data = response.data;
    } catch (_) {
      final response = await api.get(
        '/api/videos',
        queryParameters: {
          'courseId': widget.courseId,
          'isCourseSpecific': true,
          'limit': 100,
        },
      );
      data = response.data;
    }

    final videos = _extractVideos(data);
    return videos;
  }

  Future<List<StudyMaterialItem>> _fetchMaterials() async {
    final api = ApiService();
    final response = await api.get(
      '/api/study-materials/course/${widget.courseId}',
      queryParameters: {'limit': 100},
    );
    return _extractMaterials(response.data);
  }

  Future<_CourseTestSeriesData> _fetchTestsTabData() async {
    final results = await Future.wait([
      _fetchTestSeries(),
      _fetchIsEnrolled(),
    ]);
    return _CourseTestSeriesData(
      series: results[0] as List<TestSeries>,
      isEnrolled: results[1] as bool,
    );
  }

  Future<List<TestSeries>> _fetchTestSeries() async {
    final api = ApiService();
    final response =
        await api.get('/api/test-series/course/${widget.courseId}');
    return _extractTestSeries(response.data);
  }

  Future<bool> _fetchIsEnrolled() async {
    final api = ApiService();
    final response = await api.get('/api/courses/${widget.courseId}');
    final data = response.data;
    if (data is! Map) return true;
    final courseData = data['course'] is Map
        ? data['course'] as Map
        : (data['data'] is Map ? data['data'] as Map : data);
    if (courseData['isEnrolled'] == true || data['isEnrolled'] == true) {
      return true;
    }
    // If backend does not provide enrollment, avoid blocking access.
    if (!courseData.containsKey('isEnrolled') &&
        !data.containsKey('isEnrolled')) {
      return true;
    }
    return false;
  }

  List<CourseVideo> _extractVideos(dynamic data) {
    if (data is! Map) return [];
    final payload = data['data'] ?? data;
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(CourseVideo.fromJson)
          .toList();
    }
    if (payload is Map && payload['videos'] is List) {
      return (payload['videos'] as List)
          .whereType<Map<String, dynamic>>()
          .map(CourseVideo.fromJson)
          .toList();
    }
    return [];
  }

  List<StudyMaterialItem> _extractMaterials(dynamic data) {
    if (data is! Map) return [];
    final payload = data['data'] ?? data;
    if (payload is Map && payload['studyMaterials'] is List) {
      return (payload['studyMaterials'] as List)
          .whereType<Map<String, dynamic>>()
          .map(StudyMaterialItem.fromJson)
          .toList();
    }
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(StudyMaterialItem.fromJson)
          .toList();
    }
    return [];
  }

  List<TestSeries> _extractTestSeries(dynamic data) {
    if (data is! Map) return [];
    final payload = data['data'] ?? data;
    if (payload is Map && payload['testSeries'] is List) {
      return (payload['testSeries'] as List)
          .whereType<Map<String, dynamic>>()
          .map(TestSeries.fromJson)
          .toList();
    }
    if (payload is List) {
      return payload
          .whereType<Map<String, dynamic>>()
          .map(TestSeries.fromJson)
          .toList();
    }
    if (data['testSeries'] is List) {
      return (data['testSeries'] as List)
          .whereType<Map<String, dynamic>>()
          .map(TestSeries.fromJson)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final courseTitle =
        widget.title?.isNotEmpty == true ? widget.title! : 'Course';

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F4FF),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Course Panel',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.more_vert_rounded, color: AppColors.grey700),
              onPressed: () {},
            ),
          ],
        ),
        body: FutureBuilder<List<CourseVideo>>(
          future: _videosFuture,
          builder: (context, snapshot) {
            final isLoading = snapshot.connectionState != ConnectionState.done;
            final videos = snapshot.data ?? [];
            final firstVideo = videos.isNotEmpty ? videos.first : null;
            final completedCount = videos.where((e) => e.isCompleted).length;
            final totalCount = videos.length;
            final progress = totalCount == 0
                ? 0.0
                : (completedCount / totalCount).clamp(0, 1).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroVideoCard(
                    imageUrl: widget.imageUrl,
                    onTap: firstVideo != null
                        ? () => _openVideo(context, firstVideo)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTabs(),
                  const SizedBox(height: 16),
                  _buildContentHeader(completedCount, totalCount, progress),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final controller = DefaultTabController.of(context);
                      return AnimatedBuilder(
                        animation: controller,
                        builder: (_, __) {
                          if (controller.index == 1) {
                            return _buildMaterialsTab();
                          }
                          if (controller.index == 3) {
                            return _buildTestsTab();
                          }
                          if (isLoading) {
                            return const _PanelLoader();
                          }
                          if (videos.isEmpty) {
                            return const _EmptyPanel();
                          }
                          return Column(
                            children: videos
                                .map(
                                  (item) => _ContentTile(
                                    item: item,
                                    onTap: () => _openVideo(context, item),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _ReadyForQuizCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.grey600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'VIDEOS'),
          Tab(text: 'MATERIALS'),
          Tab(text: 'LIVE'),
          Tab(text: 'TESTS'),
        ],
      ),
    );
  }

  Widget _buildContentHeader(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  'Course Content',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed/$total Completed',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          _ProgressBadge(progress: progress),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return FutureBuilder<List<StudyMaterialItem>>(
      future: _materialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PanelLoader();
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const _EmptyPanel(message: 'No materials available yet.');
        }
        final docs = items.expand((item) => item.docs).toList();
        if (docs.isEmpty) {
          return const _EmptyPanel(message: 'No materials available yet.');
        }
        return Column(
          children: docs
              .map(
                (doc) => _MaterialTile(
                  doc: doc,
                  onTap: () => context.push(
                    '/pdf-viewer/${doc.id}',
                    extra: {
                      'title': doc.name,
                      'url': doc.url,
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTestsTab() {
    return FutureBuilder<_CourseTestSeriesData>(
      future: _testsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _PanelLoader();
        }
        if (snapshot.hasError) {
          return const _EmptyPanel(message: 'Unable to load test series.');
        }
        final data = snapshot.data;
        if (data == null) {
          return const _EmptyPanel(message: 'No test series available yet.');
        }
        if (!data.isEnrolled) {
          return const _EmptyPanel(
            message: 'Enroll in this course to access test series.',
          );
        }
        if (data.series.isEmpty) {
          return const _EmptyPanel(message: 'No test series available yet.');
        }
        return Column(
          children: data.series
              .map(
                (series) => _TestSeriesTile(
                  series: series,
                  onTap: () => context.go('/dashboard/test-series'),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _openVideo(BuildContext context, CourseVideo item) {
    if (item.primaryLink.isEmpty) return;
    context.push('/video-player', extra: {
      'title': item.title,
      'url': item.primaryLink,
    });
  }
}

class _HeroVideoCard extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;

  const _HeroVideoCard({
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black,
          height: 200,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                width: double.infinity,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              Container(
                height: 200,
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF111827),
        child: const Center(
          child: Icon(Icons.play_circle_fill_rounded,
              color: Colors.white30, size: 60),
        ),
      );
}

class _ProgressBadge extends StatelessWidget {
  final double progress;

  const _ProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE0FF)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: const Color(0xFFE9E6FF),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final CourseVideo item;
  final VoidCallback onTap;
  const _ContentTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitleLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    item.isCompleted ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: item.isCompleted
                      ? AppColors.primary
                      : const Color(0xFFC7CBE8),
                  width: 1.5,
                ),
              ),
              child: item.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  final StudyMaterialDoc doc;
  final VoidCallback onTap;

  const _MaterialTile({required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doc.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}

class _TestSeriesTile extends StatelessWidget {
  final TestSeries series;
  final VoidCallback onTap;

  const _TestSeriesTile({required this.series, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final testsCount = series.totalTests ?? series.tests?.length ?? 0;
    final subtitle = testsCount > 0
        ? '$testsCount Tests'
        : (series.specialization.isNotEmpty
            ? series.specialization.join(' • ')
            : 'Test Series');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.grey500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey500),
          ],
        ),
      ),
    );
  }
}

class _ReadyForQuizCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEBFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ready for the quiz?',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Complete all videos to unlock the final assessment.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class CourseVideo {
  final String id;
  final String title;
  final List<String> links;
  final bool isCompleted;

  const CourseVideo({
    required this.id,
    required this.title,
    required this.links,
    this.isCompleted = false,
  });

  String get primaryLink => links.isNotEmpty ? links.first : '';

  String get subtitleLabel {
    final link = primaryLink;
    if (link.isEmpty) return 'YouTube';
    final host = Uri.tryParse(link)?.host ?? '';
    if (host.contains('youtu')) return 'YouTube';
    return host.replaceAll('www.', '');
  }

  factory CourseVideo.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'] ?? json['link'];
    final links = <String>[];
    if (rawLinks is List) {
      links.addAll(rawLinks.whereType<String>());
    } else if (rawLinks is String && rawLinks.isNotEmpty) {
      links.add(rawLinks);
    }
    return CourseVideo(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Video',
      links: links,
    );
  }
}

class _PanelLoader extends StatelessWidget {
  const _PanelLoader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String message;
  const _EmptyPanel({this.message = 'No videos available yet.'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.grey600, fontSize: 12),
        ),
      ),
    );
  }
}

class _CourseTestSeriesData {
  final List<TestSeries> series;
  final bool isEnrolled;

  const _CourseTestSeriesData({required this.series, required this.isEnrolled});
}

class StudyMaterialItem {
  final String id;
  final String title;
  final List<StudyMaterialDoc> docs;

  const StudyMaterialItem({
    required this.id,
    required this.title,
    required this.docs,
  });

  factory StudyMaterialItem.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['docs'];
    final docs = <StudyMaterialDoc>[];
    if (rawDocs is List) {
      docs.addAll(
        rawDocs
            .whereType<Map<String, dynamic>>()
            .map(StudyMaterialDoc.fromJson),
      );
    }
    return StudyMaterialItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Material',
      docs: docs,
    );
  }
}

class StudyMaterialDoc {
  final String id;
  final String name;
  final String url;
  final String fileType;
  final int sizeInBytes;

  const StudyMaterialDoc({
    required this.id,
    required this.name,
    required this.url,
    required this.fileType,
    required this.sizeInBytes,
  });

  String get subtitle {
    final sizeKb = sizeInBytes / 1024;
    if (sizeKb > 1024) {
      final mb = (sizeKb / 1024).toStringAsFixed(1);
      return '$fileType • $mb MB';
    }
    return '$fileType • ${sizeKb.toStringAsFixed(0)} KB';
  }

  factory StudyMaterialDoc.fromJson(Map<String, dynamic> json) {
    return StudyMaterialDoc(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Document',
      url: json['url']?.toString() ?? '',
      fileType: json['fileType']?.toString() ?? 'PDF',
      sizeInBytes: (json['sizeInBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
