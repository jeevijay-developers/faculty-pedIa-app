import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/api_service.dart';
import '../../../shared/models/test_series_model.dart';
import '../../../shared/widgets/shimmer_widgets.dart';
import '../../../shared/widgets/state_widgets.dart';
import '../../../shared/widgets/user_widgets.dart';

// Test Series Provider
final testSeriesProvider = FutureProvider.autoDispose<List<TestSeries>>((ref) async {
  final api = ApiService();
  final response = await api.get('/api/test-series');
  debugPrint('RAW: ${response.data}');
  final data = response.data;
  
  List<dynamic> seriesList = [];
  if (data is Map && data['testSeries'] != null) {
    seriesList = data['testSeries'] as List;
  } else if (data is List) {
    seriesList = data;
  }
  
  return seriesList.map((e) => TestSeries.fromJson(e)).toList();
});

class TestSeriesScreen extends ConsumerWidget {
  const TestSeriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testSeriesAsync = ref.watch(testSeriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Series'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(testSeriesProvider);
        },
        child: testSeriesAsync.when(
          loading: () => const ShimmerList(itemCount: 5, itemHeight: 140),
          error: (error, stack) => ErrorStateWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(testSeriesProvider),
          ),
          data: (series) {
            if (series.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.assignment_outlined,
                title: 'No Test Series Available',
                subtitle: 'Check back later for new test series',
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: series.length,
              itemBuilder: (context, index) {
                return _TestSeriesCard(series: series[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _TestSeriesCard extends StatelessWidget {
  final TestSeries series;
  
  const _TestSeriesCard({required this.series});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/test-series/${series.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (series.educatorName != null)
                          Text(
                            'By ${series.educatorName}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  _buildStatChip(Icons.quiz, '${series.totalTests ?? 0} Tests'),
                  const SizedBox(width: 12),
                  _buildStatChip(Icons.people, '${series.enrolledCount ?? 0} Enrolled'),
                ],
              ),
              const SizedBox(height: 12),
              
              // Subjects
              if (series.subject.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: series.subject.take(3).map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.grey700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              
              // Price and Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PriceWidget(
                    price: series.fees ?? 0,
                    discount: series.discount,
                    originalPrice: series.fees,
                  ),
                  ElevatedButton(
                    onPressed: () => context.push('/test-series/${series.id}'),
                    child: const Text('View Tests'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.grey600),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}
