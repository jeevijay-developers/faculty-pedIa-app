import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/test_series_model.dart';

final testDetailProvider =
    FutureProvider.family.autoDispose<Test, String>((ref, id) async {
  final api = ApiService();
  final response = await api.get('/api/tests/$id');
  final data = response.data;

  Map<String, dynamic> testData = {};
  if (data is Map) {
    if (data['data'] is Map) {
      testData = Map<String, dynamic>.from(data['data']);
    } else if (data['test'] is Map) {
      testData = Map<String, dynamic>.from(data['test']);
    } else {
      testData = Map<String, dynamic>.from(data);
    }
  }

  return Test.fromJson(testData);
});

class LiveTestScreen extends ConsumerStatefulWidget {
  final String testId;

  const LiveTestScreen({super.key, required this.testId});

  @override
  ConsumerState<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends ConsumerState<LiveTestScreen> {
  int _currentQuestion = 0;
  final Map<int, int?> _answers = {};
  Duration _remainingTime = const Duration(minutes: 60);
  bool _testStarted = false;
  Timer? _timer;
  Test? _activeTest;
  int _testDurationMinutes = 60;

  @override
  Widget build(BuildContext context) {
    final testAsync = ref.watch(testDetailProvider(widget.testId));

    return testAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Test Instructions')),
        body: Center(child: Text('Failed to load test: $error')),
      ),
      data: (test) {
        _activeTest = test;
        if (!_testStarted) {
          return _buildStartScreen(test);
        }
        return _buildTestScreen(test);
      },
    );
  }

  Widget _buildTestScreen(Test test) {
    final questions = test.questions ?? const <Question>[];
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Live Test')),
        body: Center(
          child: Text(
            'No questions available for this test.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    if (_currentQuestion >= questions.length) {
      _currentQuestion = 0;
    }

    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentQuestion + 1}/${questions.length}'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _showExitDialog()) {
                if (mounted) context.pop();
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingTime.inMinutes < 5
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _remainingTime.inMinutes < 5
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatCountdown(_remainingTime),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _remainingTime.inMinutes < 5
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / questions.length,
              backgroundColor: AppColors.grey200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number and marks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question ${_currentQuestion + 1}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '+${questions[_currentQuestion].marks ?? 4}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(' / '),
                            Text(
                              '-${questions[_currentQuestion].negativeMarks ?? 1}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Question text
                    Text(
                      questions[_currentQuestion].text ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Options
                    ...questions[_currentQuestion]
                        .options
                        .asMap()
                        .entries
                        .map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _answers[_currentQuestion] == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _answers[_currentQuestion] = index;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.grey300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.grey100,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.grey600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option.text ?? '',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.grey800,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestion > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestion--;
                          });
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestion > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentQuestion > 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentQuestion < questions.length - 1) {
                          setState(() {
                            _currentQuestion++;
                          });
                        } else {
                          _submitTest(test);
                        }
                      },
                      child: Text(
                        _currentQuestion < questions.length - 1
                            ? 'Next'
                            : 'Submit Test',
                      ),
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

  Widget _buildStartScreen(Test test) {
    final durationMinutes = test.duration ?? 60;
    final createdAt = test.createdAt;
    final questions = test.questions ?? const <Question>[];
    final totalMarks = questions.isEmpty
        ? 0
        : questions.fold<int>(
            0,
            (sum, q) => sum + (q.marks ?? 0),
          );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Instructions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Practice Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildInfoChip(
                          Icons.quiz, '${questions.length} Questions'),
                      _buildInfoChip(Icons.timer, '$durationMinutes Minutes'),
                      _buildInfoChip(Icons.star, '$totalMarks Marks'),
                    ],
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      'Created: ${DateFormatter.formatDateTime(createdAt)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            Text(
              'Instructions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
                '1', 'This test contains ${questions.length} questions.'),
            _buildInstructionItem(
                '2', 'Total time allowed is $durationMinutes minutes.'),
            _buildInstructionItem('3', 'Each correct answer carries 4 marks.'),
            _buildInstructionItem(
                '4', 'Each wrong answer has 1 mark negative.'),
            _buildInstructionItem('5', 'Unattempted questions carry no marks.'),
            _buildInstructionItem(
                '6', 'You can review and change answers before submission.'),
            const SizedBox(height: 32),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  _startTest(durationMinutes);
                },
                child: const Text('Start Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text(
            'Are you sure you want to exit? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _startTest(int durationMinutes) {
    _timer?.cancel();
    setState(() {
      _testStarted = true;
      _testDurationMinutes = durationMinutes;
      _remainingTime = Duration(minutes: durationMinutes);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        final next = _remainingTime - const Duration(seconds: 1);
        _remainingTime = next.isNegative ? Duration.zero : next;
      });

      if (_remainingTime.inSeconds <= 0) {
        timer.cancel();
        final test = _activeTest;
        if (test != null) {
          _submitTest(test);
        }
      }
    });
  }

  void _submitTest(Test test) {
    _timer?.cancel();
    final questions = test.questions ?? const <Question>[];
    final totalDurationSeconds = _testDurationMinutes * 60;
    final timeSpentSeconds = totalDurationSeconds - _remainingTime.inSeconds;

    int correct = 0;
    int wrong = 0;
    int attempted = 0;
    int totalMarks = 0;
    int score = 0;

    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      final selected = _answers[i];
      final correctIndex = _resolveCorrectIndex(q);
      final positive = q.marks ?? 0;
      final negative = q.negativeMarks ?? 0;
      totalMarks += positive;

      if (selected == null) {
        continue;
      }
      attempted++;

      if (correctIndex != null && selected == correctIndex) {
        correct++;
        score += positive;
      } else {
        wrong++;
        score -= negative;
      }
    }

    if (totalMarks == 0 && questions.isNotEmpty) {
      totalMarks = questions.length * 4;
    }
    if (score < 0) score = 0;

    final unattempted = questions.length - attempted;
    final percentage =
        totalMarks > 0 ? (score / totalMarks * 100).clamp(0, 100) : 0.0;
    final accuracy =
        attempted > 0 ? (correct / attempted * 100).clamp(0, 100) : 0.0;
    final pace = _paceLabel(timeSpentSeconds, totalDurationSeconds);

    final resultData = <String, dynamic>{
      'testId': test.id,
      'title': test.title ?? 'Test',
      'score': score,
      'totalMarks': totalMarks,
      'correct': correct,
      'wrong': wrong,
      'unattempted': unattempted,
      'percentage': percentage,
      'accuracy': accuracy,
      'pace': pace,
      'timeSpentSeconds': timeSpentSeconds,
      'totalDurationSeconds': totalDurationSeconds,
    };

    context.go(
      '/test-result/${widget.testId}',
      extra: resultData,
    );
  }

  int? _resolveCorrectIndex(Question question) {
    final value = question.correctOption ?? question.correctOptions;
    if (value is int) return value;
    if (value is String) return _labelToIndex(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is int) return first;
      if (first is String) return _labelToIndex(first);
    }
    return null;
  }

  int? _labelToIndex(String label) {
    switch (label.trim().toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return null;
    }
  }

  String _paceLabel(int spentSeconds, int totalSeconds) {
    if (totalSeconds <= 0) return '—';
    final ratio = spentSeconds / totalSeconds;
    if (ratio <= 0.5) return 'Fast';
    if (ratio <= 0.85) return 'Average';
    return 'Slow';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
