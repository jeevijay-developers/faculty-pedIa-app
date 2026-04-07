import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/test_series_model.dart';
import '../../shared/models/hamburger_model.dart';
import '../../shared/widgets/state_widgets.dart';
import '../auth/providers/auth_provider.dart';

class StudentTestSeriesItem {
  final TestSeries series;
  final int totalTests;
  final List<Test> tests;

  const StudentTestSeriesItem({
    required this.series,
    required this.totalTests,
    required this.tests,
  });
}

final studentTestSeriesProvider =
    FutureProvider.autoDispose<List<StudentTestSeriesItem>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final studentId = authState.student?.id;

  if (studentId == null || studentId.isEmpty) {
    throw Exception('Student not found');
  }

  final api = ApiService();
  final response = await api.get('/api/students/$studentId');
  final payload = response.data is Map<String, dynamic>
      ? response.data as Map<String, dynamic>
      : <String, dynamic>{};
  final data = payload['data'] is Map<String, dynamic>
      ? payload['data'] as Map<String, dynamic>
      : payload;

  final rawSeries = (data['testSeries'] ?? data['tests']);
  if (rawSeries is! List) return const [];

  final ids = <String>{};
  for (final entry in rawSeries) {
    if (entry is Map && entry['testSeriesId'] != null) {
      final rawId = entry['testSeriesId'];
      if (rawId is String) {
        ids.add(rawId);
      } else if (rawId is Map && rawId['_id'] != null) {
        ids.add(rawId['_id'].toString());
      }
    }
  }

  if (ids.isEmpty) return const [];

  final items = await Future.wait(ids.map((id) async {
    final res = await api.get('/api/test-series/$id');
    final payload = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
        : <String, dynamic>{};

    Map<String, dynamic> seriesData = {};
    if (payload['testSeries'] is Map) {
      seriesData = Map<String, dynamic>.from(payload['testSeries']);
    } else if (payload['data'] is Map) {
      final nested = payload['data'] as Map;
      if (nested['testSeries'] is Map) {
        seriesData = Map<String, dynamic>.from(nested['testSeries']);
      } else {
        seriesData = Map<String, dynamic>.from(nested);
      }
    } else {
      seriesData = Map<String, dynamic>.from(payload);
    }

    final series = TestSeries.fromJson(seriesData);

    final testsRes = await api.get('/api/tests/test-series/$id',
        queryParameters: const {'limit': 200});
    final testsPayload = testsRes.data is Map<String, dynamic>
        ? testsRes.data as Map<String, dynamic>
        : <String, dynamic>{};
    final testsData = testsPayload['data'] is Map<String, dynamic>
        ? testsPayload['data'] as Map<String, dynamic>
        : <String, dynamic>{};
    final rawTests = (testsData['tests'] ?? testsPayload['tests']) is List
        ? (testsData['tests'] ?? testsPayload['tests']) as List
        : const <dynamic>[];

    final apiTests = rawTests
        .whereType<Map<String, dynamic>>()
        .map(Test.fromJson)
        .where((test) => test.id.isNotEmpty)
        .toList();

    final seriesTests = (series.tests ?? const <Test>[])
        .where((test) => test.id.isNotEmpty)
        .toList();

    final tests = apiTests.isNotEmpty ? apiTests : seriesTests;
    final totalTests =
        tests.isNotEmpty ? tests.length : (series.totalTests ?? 0);

    return StudentTestSeriesItem(
      series: series,
      totalTests: totalTests,
      tests: tests,
    );
  }));

  return items.where((item) => item.series.id.isNotEmpty).toList();
});

class StudentTestSeriesScreen extends ConsumerWidget {
  const StudentTestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final displayName = authState.user?.displayName ?? 'Student';
    final testSeriesAsync = ref.watch(studentTestSeriesProvider);

    return Scaffold(
      drawer: const HamburgerDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.grey900),
        title: const Text(
          'Academic Atelier',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF6F4FF),
        child: testSeriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(studentTestSeriesProvider),
          ),
          data: (items) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(studentTestSeriesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $displayName 👋',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ready to continue your learning journey today?',
                      style: TextStyle(color: AppColors.grey600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      const EmptyStateWidget(
                        icon: Icons.assignment_outlined,
                        title: 'No test series yet',
                        subtitle:
                            'Enroll in a test series to track your progress here.',
                      )
                    else
                      ...items.map((item) => _TestSeriesCard(item: item)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TestSeriesCard extends StatelessWidget {
  final StudentTestSeriesItem item;

  const _TestSeriesCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final series = item.series;
    final tests = item.tests;
    final hasTests = tests.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 14),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.grey700,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                series.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                series.description?.isNotEmpty == true
                    ? series.description!
                    : 'Comprehensive test series to boost your preparation',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${item.totalTests} tests',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.grey700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            if (!hasTests)
              _EmptyTestsNote(seriesId: series.id)
            else
              Column(
                children:
                    tests.map((test) => _SeriesTestCard(test: test)).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeriesTestCard extends StatelessWidget {
  final Test test;

  const _SeriesTestCard({required this.test});

  @override
  Widget build(BuildContext context) {
    final title = test.title?.isNotEmpty == true ? test.title! : 'Test';
    final subtitle = test.description?.isNotEmpty == true
        ? test.description!
        : 'Any Student can give this test.';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: test.id.isEmpty
                ? null
                : () => context.push('/live-test/${test.id}'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Start Test',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTestsNote extends StatelessWidget {
  final String seriesId;

  const _EmptyTestsNote({required this.seriesId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.grey500),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'No tests are available in this series yet.',
              style: TextStyle(fontSize: 12, color: AppColors.grey600),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/test-series/$seriesId'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              foregroundColor: AppColors.primary,
            ),
            child: const Text(
              'Details',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
