import 'package:flutter/material.dart';

class StepContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isActive;
  final bool isCompleted;

  const StepContainer({
    super.key,
    required this.title,
    required this.child,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isCompleted)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 20,
                ),
              if (isCompleted) const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getTitleColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isActive || isCompleted) child,
          if (!isActive && !isCompleted)
            const Text(
              'Complete previous steps first',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (isCompleted) return Colors.green.shade50;
    if (isActive) return Colors.blue.shade50;
    return Colors.grey.shade100;
  }

  Color _getBorderColor() {
    if (isCompleted) return Colors.green.shade300;
    if (isActive) return Colors.blue.shade300;
    return Colors.grey.shade300;
  }

  Color _getTitleColor() {
    if (isCompleted) return Colors.green.shade700;
    if (isActive) return Colors.blue.shade700;
    return Colors.grey.shade700;
  }
}