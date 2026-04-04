import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ExamsScreen extends ConsumerWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exams = [
      {
        'name': 'IIT-JEE',
        'fullName':
            'Indian Institutes of Technology Joint Entrance Examination',
        'icon': Icons.science,
        'color': AppColors.primary,
        'route': '/exam-content/iit-jee',
        'description': 'Engineering entrance exam for IITs and NITs',
        'subjects': ['Physics', 'Chemistry', 'Mathematics'],
      },
      {
        'name': 'NEET',
        'fullName': 'National Eligibility cum Entrance Test',
        'icon': Icons.medical_services,
        'color': AppColors.secondary,
        'route': '/exam-content/neet',
        'description': 'Medical entrance exam for MBBS and BDS courses',
        'subjects': ['Physics', 'Chemistry', 'Biology'],
      },
      {
        'name': 'CBSE',
        'fullName': 'Central Board of Secondary Education',
        'icon': Icons.school,
        'color': AppColors.accent,
        'route': '/exam-content/cbse',
        'description': 'Board exams for Classes 10 and 12',
        'subjects': ['All Subjects'],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exams'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];
          return _ExamCard(exam: exam);
        },
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Map<String, dynamic> exam;

  const _ExamCard({required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push(exam['route'] as String),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: (exam['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      exam['icon'] as IconData,
                      color: exam['color'] as Color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['name'] as String,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: exam['color'] as Color,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exam['fullName'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.grey400,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                exam['description'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (exam['subjects'] as List<String>).map((subject) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (exam['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: exam['color'] as Color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
