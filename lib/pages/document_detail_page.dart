import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../cloud/rls_policy_engine.dart';
import '../colors.dart';
import '../database/database_global.dart';
import '../struct/formatters.dart';
import '../struct/models.dart';
import '../widgets/priority_indicator.dart';
import '../widgets/share_document_sheet.dart';
import '../widgets/status_chip.dart';
import 'add_edit_document_page.dart';

/// Màn hình Chi tiết Tài liệu học tập (Document Detail Page)
/// Tích hợp hiển thị Phân quyền RLS (Supabase) và Đường dẫn Lưu trữ (Firebase Storage).
class DocumentDetailPage extends StatelessWidget {
  final String documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<StudyDocument?>(
      stream: database.watchDocumentById(documentId),
      builder: (context, snapshot) {
        final doc = snapshot.data;

        if (doc == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tài liệu không tồn tại, đã bị xóa hoặc bạn không có quyền truy cập (Chặn bởi Supabase RLS).',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final permission = database.getEffectivePermission(doc.id);

        return FutureBuilder<Subject?>(
          future: database.getSubjectById(doc.subjectId),
          builder: (context, subSnapshot) {
            final subject = subSnapshot.data;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Chi tiết tài liệu'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Chia sẻ & Phân quyền',
                    onPressed: () => ShareDocumentSheet.show(context, doc),
                  ),
                  IconButton(
                    icon: Icon(
                      doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: doc.isFavorite ? AppColors.accentAmber : null,
                    ),
                    onPressed: () async {
                      try {
                        await database.toggleFavorite(doc.id);
                      } on RlsAccessDeniedException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      if (!permission.canEdit) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Từ chối truy cập (RLS): Quyền "${permission.shortLabel}" không được phép chỉnh sửa tài liệu.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => AddEditDocumentPage(initialDocument: doc),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    onPressed: () {
                      if (!permission.canDelete) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Từ chối truy cập (RLS): Chỉ Chủ sở hữu mới được xóa tài liệu. Quyền hiện tại: ${permission.shortLabel}.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _confirmDelete(context, doc);
                    },
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hàng tiêu đề loại + Mức độ ưu tiên + Status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: doc.type.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(doc.type.icon, size: 16, color: doc.type.color),
                              const SizedBox(width: 6),
                              Text(
                                doc.type.displayName,
                                style: TextStyle(
                                  color: doc.type.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityIndicator(priority: doc.priority),
                        const Spacer(),
                        StatusChip(
                          status: doc.status,
                          onStatusChanged: permission.canEdit
                              ? (newStatus) {
                                  database.updateDocumentStatus(doc.id, newStatus);
                                }
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tiêu đề lớn
                    Text(
                      doc.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Thẻ Quyền truy cập & Chia sẻ Cloud (Supabase RLS)
                    _buildCloudPermissionCard(context, doc, permission, isDark),
                    const SizedBox(height: 16),

                    // Thông tin Môn học (Card)
                    if (subject != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: subject.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.school_rounded, color: subject.color),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${subject.code} - ${subject.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'GV: ${subject.lecturer.isNotEmpty ? subject.lecturer : "Chưa cập nhật"} • ${subject.creditCount} tín chỉ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Hạn nộp / Deadline card nếu có
                    if (doc.dueDate != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: doc.isOverdue
                              ? AppColors.priorityUrgent.withValues(alpha: 0.1)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: doc.isOverdue
                                ? AppColors.priorityUrgent.withValues(alpha: 0.5)
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              doc.isOverdue ? Icons.alarm_off_rounded : Icons.alarm_on_rounded,
                              color: doc.isOverdue ? AppColors.priorityUrgent : AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.isOverdue ? 'ĐÃ QUÁ HẠN NỘP' : 'HẠN HOÀN THÀNH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: doc.isOverdue ? AppColors.priorityUrgent : Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DocumentFormatters.formatDueDate(doc.dueDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: doc.isOverdue
                                        ? AppColors.priorityUrgent
                                        : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.lightTextPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Ghi chú / Mô tả
                    if (doc.description.isNotEmpty) ...[
                      const Text(
                        'Nội dung & Ghi chú',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Text(
                          doc.description,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Thẻ Lưu trữ Vật lý trên Firebase Storage & Liên kết tệp tin
                    if (doc.fileUrl.isNotEmpty || doc.storagePath.isNotEmpty) ...[
                      const Text(
                        'Lưu trữ Vật lý (Firebase Storage) & Liên kết Tệp',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (doc.storagePath.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(
                                    Icons.cloud_done_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      doc.fileName.isNotEmpty
                                          ? '${doc.fileName} (${DocumentFormatters.formatFileSize(doc.fileSizeBytes)})'
                                          : DocumentFormatters.formatFileSize(doc.fileSizeBytes),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      doc.fileType,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Storage Path: ${doc.storagePath}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontFamily: 'monospace',
                                  color: Colors.grey,
                                ),
                              ),
                              const Divider(height: 16),
                            ],
                            Row(
                              children: [
                                const Icon(Icons.link_rounded, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    doc.fileUrl,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: doc.fileUrl));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Đã sao chép liên kết')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Tags
                    if (doc.tags.isNotEmpty) ...[
                      const Text(
                        'Thẻ phân loại (#Tags)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: doc.tags.map((tag) {
                          return Chip(
                            label: Text('#$tag', style: const TextStyle(fontSize: 12)),
                            backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Thời gian tạo và cập nhật
                    Text(
                      'Tạo ngày: ${DocumentFormatters.formatDateTime(doc.createdAt)} • Cập nhật: ${DocumentFormatters.formatDateTime(doc.updatedAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // Nút chuyển trạng thái hoàn thành nhanh (Chỉ khả dụng nếu có quyền Edit/Owner)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: permission.canEdit
                            ? () {
                                final newStatus = doc.status == DocumentStatus.completed
                                    ? DocumentStatus.inProgress
                                    : DocumentStatus.completed;
                                database.updateDocumentStatus(doc.id, newStatus);
                              }
                            : null,
                        icon: Icon(
                          doc.status == DocumentStatus.completed
                              ? Icons.replay_rounded
                              : Icons.check_circle_outline_rounded,
                        ),
                        label: Text(
                          !permission.canEdit
                              ? 'CHẾ ĐỘ CHỈ XEM (VIEWER - RLS)'
                              : (doc.status == DocumentStatus.completed
                                  ? 'ĐÁNH DẤU CHƯA XONG'
                                  : 'ĐÁNH DẤU ĐÃ HOÀN THÀNH'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doc.status == DocumentStatus.completed
                              ? Colors.grey[700]
                              : AppColors.statusCompleted,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCloudPermissionCard(
    BuildContext context,
    StudyDocument doc,
    PermissionLevel permission,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: permission.color.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(permission.icon, color: permission.color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quyền của bạn: ${permission.displayName}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: permission.color,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => ShareDocumentSheet.show(context, doc),
                icon: const Icon(Icons.group_add_rounded, size: 16),
                label: const Text('Chia sẻ', style: TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
          Text(
            'Chủ sở hữu gốc: ${doc.ownerName} (${doc.ownerEmail})',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<List<DocumentPermission>>(
            stream: database.watchPermissionsForDocument(doc.id),
            builder: (context, permSnap) {
              final perms = permSnap.data ?? [];
              if (perms.isEmpty) {
                return const Text(
                  'Trạng thái chia sẻ: Riêng tư (chỉ Chủ sở hữu truy cập)',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey),
                );
              }
              return Wrap(
                spacing: 6,
                runSpacing: 4,
                children: perms.map((p) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.permissionLevel.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${p.sharedWithEmail} (${p.permissionLevel.shortLabel})',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: p.permissionLevel.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, StudyDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await database.deleteDocument(doc.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa tài liệu và tệp trên Cloud Storage')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
