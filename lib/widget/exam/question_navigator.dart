import 'package:flutter/material.dart';

class QuestionNavigator extends StatelessWidget {
  final int totalQuestions;
  final Map<int, int> answeredQuestions; // Map questionDetailId -> answerId
  final List<int> questionIds; // List của tất cả questionDetailId theo thứ tự
  final int currentIndex;
  final Function(int index) onQuestionTap;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool autoNext;
  final ValueChanged<bool>? onAutoNextChanged;

  const QuestionNavigator({
    Key? key,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.questionIds,
    required this.currentIndex,
    required this.onQuestionTap,
    this.onPrevious,
    this.onNext,
    this.onSubmit,
    this.autoNext = false,
    this.onAutoNextChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLastQuestion = currentIndex >= totalQuestions - 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Checkbox tự động chuyển trang
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: autoNext,
              onChanged: (value) => onAutoNextChanged?.call(value ?? false),
              activeColor: Colors.blue,
            ),
            GestureDetector(
              onTap: () => onAutoNextChanged?.call(!autoNext),
              child: Text(
                'Tự động chuyển câu',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        Row(
          children: [
            // Nút Trước
            Expanded(
              child: ElevatedButton.icon(
                onPressed: currentIndex > 0 ? onPrevious : null,
                icon: Icon(Icons.arrow_back),
                label: Text('Trước'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.grey[200],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),

            // Nút xem danh sách câu hỏi
            Container(
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.grid_view, color: Colors.white, size: 28),
                onPressed: () {
                  _showQuestionGrid(context);
                },
                tooltip: 'Xem danh sách câu hỏi',
              ),
            ),
            SizedBox(width: 8),

            // Nút Tiếp/Nộp bài
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLastQuestion ? onSubmit : onNext,
                icon: Icon(
                  isLastQuestion ? Icons.check_circle : Icons.arrow_forward,
                ),
                label: Text(isLastQuestion ? 'Nộp bài' : 'Tiếp theo'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showQuestionGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Danh sách câu hỏi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Thống kê
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Tổng số',
                      totalQuestions.toString(),
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Đã làm',
                      answeredQuestions.length.toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Chưa làm',
                      (totalQuestions - answeredQuestions.length).toString(),
                      Colors.orange,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Chú thích
              Row(
                children: [
                  _buildLegend(Colors.green, 'Đã trả lời'),
                  SizedBox(width: 16),
                  _buildLegend(Colors.blue, 'Đang làm'),
                  SizedBox(width: 16),
                  _buildLegend(Colors.grey[300]!, 'Chưa làm'),
                ],
              ),
              SizedBox(height: 16),

              // Grid câu hỏi
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: totalQuestions,
                  itemBuilder: (context, index) {
                    final questionId = questionIds[index];
                    final isAnswered = answeredQuestions.containsKey(
                      questionId,
                    );
                    final isCurrent = index == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onQuestionTap(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Colors.blue
                              : isAnswered
                              ? Colors.green
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? Colors.blue[700]!
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: (isCurrent || isAnswered)
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
