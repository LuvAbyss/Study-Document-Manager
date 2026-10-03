import 'package:flutter/material.dart';
import '../struct/models.dart';
import '../struct/formatters.dart';
import '../colors.dart';
import 'subject_badge.dart';
import 'priority_indicator.dart';
import 'status_chip.dart';

/// Thẻ hiển thị tài liệu học tập theo chuẩn thiết kế Cashew
class DocumentCard extends StatelessWidget {
  final StudyDocument document;
  final Subject? subject;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final ValueChanged<DocumentStatus>? onStatusChanged;

  const DocumentCard({
    super.key,
    required this.document,
    this.subject,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final type = document.type;
    final typeColor = type.color;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: document.isOverdue
              ? AppColors.priorityUrgent.withValues(alpha: 0.5)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: document.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hàng 1: Loại tài liệu icon + Tên môn học + Favorite + Action Menu
                Row(
                  children: [
                    // Icon loại tài liệu
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(type.icon, color: typeColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    // Subject Badge
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SubjectBadge(subject: subject, compact: true),
                      ),
                    ),
                    // Favorite button
                    IconButton(
                      icon: Icon(
                        document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: document.isFavorite ? AppColors.accentAmber : Colors.grey,
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      onPressed: onToggleFavorite,
                    ),
                    const SizedBox(width: 8),
                    // Action Menu Popup
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) {
                        if (val == 'edit') onEdit?.call();
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Chỉnh sửa'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Xóa tài liệu', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Hàng 2: Tiêu đề tài liệu
                Text(
                  document.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    decoration: document.status == DocumentStatus.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: document.status == DocumentStatus.completed
                        ? Colors.grey
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Mô tả ngắn nếu có
                if (document.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    document.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 10),

                // Hàng 3: Hạn nộp & Thông tin kích thước / đường dẫn
                if (document.dueDate != null) ...[
                  Row(
                    children: [
                      Icon(
                        document.isOverdue
                            ? Icons.error_outline_rounded
                            : Icons.access_time_rounded,
                        size: 14,
                        color: document.isOverdue ? AppColors.priorityUrgent : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hạn: ${DocumentFormatters.formatDueDate(document.dueDate)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: document.isOverdue ? FontWeight.bold : FontWeight.w500,
                          color: document.isOverdue ? AppColors.priorityUrgent : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Hàng 4: Status + Priority + File format badge
                Row(
                  children: [
                    StatusChip(
                      status: document.status,
                      onStatusChanged: onStatusChanged,
                    ),
                    const SizedBox(width: 8),
                    PriorityIndicator(priority: document.priority),
                    const Spacer(),
                    if (document.fileType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          document.fileType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
