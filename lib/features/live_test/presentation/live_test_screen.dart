import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/test_series_model.dart';

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

  // Sample questions for demo
  final List<Question> _questions = [
    Question(
      id: '1',
      text: 'What is the value of acceleration due to gravity on Earth?',
      options: [
        Option(index: 0, text: '9.8 m/s²'),
        Option(index: 1, text: '10.8 m/s²'),
        Option(index: 2, text: '8.8 m/s²'),
        Option(index: 3, text: '11.8 m/s²'),
      ],
      marks: 4,
      negativeMarks: 1,
    ),
    Question(
      id: '2',
      text: 'Which of the following is a noble gas?',
      options: [
        Option(index: 0, text: 'Nitrogen'),
        Option(index: 1, text: 'Oxygen'),
        Option(index: 2, text: 'Helium'),
        Option(index: 3, text: 'Hydrogen'),
      ],
      marks: 4,
      negativeMarks: 1,
    ),
    Question(
      id: '3',
      text: 'What is the derivative of x²?',
      options: [
        Option(index: 0, text: 'x'),
        Option(index: 1, text: '2x'),
        Option(index: 2, text: 'x²'),
        Option(index: 3, text: '2'),
      ],
      marks: 4,
      negativeMarks: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_testStarted) {
      return _buildStartScreen();
    }
    
    return WillPopScope(
      onWillPop: () async {
        return await _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question ${_currentQuestion + 1}/${_questions.length}'),
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
              value: (_currentQuestion + 1) / _questions.length,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              '+${_questions[_currentQuestion].marks ?? 4}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(' / '),
                            Text(
                              '-${_questions[_currentQuestion].negativeMarks ?? 1}',
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
                      _questions[_currentQuestion].text ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Options
                    ..._questions[_currentQuestion].options.asMap().entries.map((entry) {
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
                        if (_currentQuestion < _questions.length - 1) {
                          setState(() {
                            _currentQuestion++;
                          });
                        } else {
                          _submitTest();
                        }
                      },
                      child: Text(
                        _currentQuestion < _questions.length - 1
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

  Widget _buildStartScreen() {
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
                      _buildInfoChip(Icons.quiz, '${_questions.length} Questions'),
                      _buildInfoChip(Icons.timer, '60 Minutes'),
                      _buildInfoChip(Icons.star, '${_questions.length * 4} Marks'),
                    ],
                  ),

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
            _buildInstructionItem('1', 'This test contains ${_questions.length} questions.'),
            _buildInstructionItem('2', 'Total time allowed is 60 minutes.'),
            _buildInstructionItem('3', 'Each correct answer carries 4 marks.'),
            _buildInstructionItem('4', 'Each wrong answer has 1 mark negative.'),
            _buildInstructionItem('5', 'Unattempted questions carry no marks.'),
            _buildInstructionItem('6', 'You can review and change answers before submission.'),
            const SizedBox(height: 32),
            
            // Start button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _testStarted = true;
                  });
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
        content: const Text('Are you sure you want to exit? Your progress will be lost.'),
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

  void _submitTest() {
    // Calculate score
    int attempted = _answers.length;
    int correct = 0; // Would calculate from correct answers
    int score = correct * 4;
    
    // Navigate to results
    context.go('/test-result/${widget.testId}');
  }
}
