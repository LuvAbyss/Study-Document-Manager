import 'package:flutter/material.dart';
import '../struct/models.dart';

/// Huy hiệu mức độ ưu tiên (Priority Indicator)
class PriorityIndicator extends StatelessWidget {
  final Priority priority;
  final bool showLabel;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = priority.color;

    if (!showLabel) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            priority == Priority.urgent
                ? Icons.warning_amber_rounded
                : Icons.flag_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
