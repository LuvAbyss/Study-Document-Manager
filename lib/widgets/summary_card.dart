import 'package:flutter/material.dart';
import '../struct/models.dart';
import '../colors.dart';

/// Thẻ tóm tắt các chỉ số học tập trên màn hình chính (Cashew Dashboard Summary)
class DashboardSummarySection extends StatelessWidget {
  final StudyStatistics statistics;
  final VoidCallback? onPendingAssignmentsTap;
  final VoidCallback? onUrgentTap;

  const DashboardSummarySection({
    super.key,
    required this.statistics,
    this.onPendingAssignmentsTap,
    this.onUrgentTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khối tiến độ tổng quan (Main Progress Card)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
                    : [const Color(0xFF1E88E5), const Color(0xFF1565C0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiến độ học tập tổng thể',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(statistics.completionRate * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: statistics.completionRate,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã hoàn thành: ${statistics.completedDocuments}/${statistics.totalDocuments} tài liệu',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                      ),
                    ),
                    if (statistics.overdueAssignments > 0)
                      Text(
                        '⚠️ ${statistics.overdueAssignments} bài quá hạn',
                        style: const TextStyle(
                          color: Color(0xFFFFCDD2),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lưới các thẻ chỉ số phụ
          Row(
            children: [
              // Thẻ 1: Tổng tài liệu
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Tổng tài liệu',
                  count: statistics.totalDocuments.toString(),
                  icon: Icons.folder_copy_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              // Thẻ 2: Bài tập cần làm
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Bài tập cần nộp',
                  count: statistics.pendingAssignments.toString(),
                  icon: Icons.assignment_late_rounded,
                  color: AppColors.typeAssignment,
                  isDark: isDark,
                  onTap: onPendingAssignmentsTap,
                ),
              ),
              const SizedBox(width: 10),
              // Thẻ 3: Việc khẩn cấp
              Expanded(
                child: _buildMetricTile(
                  context,
                  title: 'Khẩn cấp',
                  count: statistics.urgentCount.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.priorityUrgent,
                  isDark: isDark,
                  onTap: onUrgentTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
