import 'package:flutter/material.dart';
import '../struct/models.dart';

/// Chip hiển thị và chuyển đổi nhanh trạng thái tài liệu
class StatusChip extends StatelessWidget {
  final DocumentStatus status;
  final ValueChanged<DocumentStatus>? onStatusChanged;

  const StatusChip({
    super.key,
    required this.status,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (onStatusChanged != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: color),
          ],
        ],
      ),
    );

    if (onStatusChanged == null) return child;

    return PopupMenuButton<DocumentStatus>(
      initialValue: status,
      onSelected: onStatusChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => DocumentStatus.values.map((s) {
        return PopupMenuItem<DocumentStatus>(
          value: s,
          child: Row(
            children: [
              Icon(s.icon, size: 16, color: s.color),
              const SizedBox(width: 8),
              Text(
                s.displayName,
                style: TextStyle(
                  fontWeight: s == status ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: child,
    );
  }
}
