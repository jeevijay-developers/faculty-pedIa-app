import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/test_series_model.dart';
import '../../../shared/widgets/state_widgets.dart';

// Test Series Detail Provider
final testSeriesDetailProvider = FutureProvider.family.autoDispose<TestSeries, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/test-series/$id');
  final data = response.data;
  
  Map<String, dynamic> seriesData = {};
  if (data is Map && data['testSeries'] != null) {
    seriesData = data['testSeries'];
  } else if (data is Map) {
    seriesData = Map<String, dynamic>.from(data);
  }
  
  return TestSeries.fromJson(seriesData);
});

class TestSeriesDetailsScreen extends ConsumerWidget {
  final String testSeriesId;
  
  const TestSeriesDetailsScreen({super.key, required this.testSeriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(testSeriesDetailProvider(testSeriesId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series'),
      ),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(testSeriesDetailProvider(testSeriesId)),
        ),
        data: (series) => _buildContent(context, series),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TestSeries series) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    series.specialization.isNotEmpty
                        ? series.specialization.first
                        : 'Test Series',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  series.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (series.educatorName != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        series.educatorName!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Tests', '${series.totalTests ?? 0}', Icons.quiz)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Enrolled', '${series.enrolledCount ?? 0}', Icons.people)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Price', '₹${series.fees?.toInt() ?? 0}', Icons.attach_money)),
              ],
            ),
          ),
          
          // Description
          if (series.description != null && series.description!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    series.description!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Tests List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Available Tests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 12),
          
          if (series.tests != null && series.tests!.isNotEmpty)
            ...series.tests!.map((test) => _buildTestItem(context, test))
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.assignment_outlined, size: 48, color: AppColors.grey400),
                    const SizedBox(height: 12),
                    Text(
                      'No tests available yet',
                      style: TextStyle(color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestItem(BuildContext context, Test test) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/live-test/${test.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_document, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title ?? 'Test',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTestInfo(Icons.quiz, '${test.totalQuestions ?? 0} Q'),
                        const SizedBox(width: 12),
                        _buildTestInfo(Icons.timer, '${test.duration ?? 0} min'),
                        const SizedBox(width: 12),
                        _buildTestInfo(Icons.star, '${test.totalMarks ?? 0} marks'),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.push('/live-test/${test.id}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ),
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
          style: TextStyle(fontSize: 11, color: AppColors.grey600),
        ),
      ],
    );
  }
}
