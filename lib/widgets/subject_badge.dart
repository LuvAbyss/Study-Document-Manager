import 'package:flutter/material.dart';
import '../struct/models.dart';

/// Huy hiệu hiển thị môn học (Subject Badge)
class SubjectBadge extends StatelessWidget {
  final Subject? subject;
  final bool compact;

  const SubjectBadge({
    super.key,
    required this.subject,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (subject == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Chưa phân loại',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      );
    }

    final color = subject!.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            compact ? subject!.code : '${subject!.code} - ${subject!.name}',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
