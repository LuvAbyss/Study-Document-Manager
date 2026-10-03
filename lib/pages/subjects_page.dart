import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../struct/models.dart';
import '../struct/document_service.dart';
import '../database/database_global.dart';
import '../colors.dart';
import 'document_list_page.dart';

/// Màn hình Quản lý Môn học / Học phần (Subjects Management Page)
class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddSubjectDialog(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm môn học'),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: database.watchAllSubjects(),
        builder: (context, subjectSnapshot) {
          final subjects = subjectSnapshot.data ?? [];

          return StreamBuilder<List<StudyDocument>>(
            stream: database.watchAllDocuments(),
            builder: (context, docSnapshot) {
              final documents = docSnapshot.data ?? [];

              // Tính số lượng tài liệu cho từng môn
              final docCountBySubject = <String, int>{};
              for (var doc in documents) {
                docCountBySubject[doc.subjectId] =
                    (docCountBySubject[doc.subjectId] ?? 0) + 1;
              }

              if (subjects.isEmpty) {
                return const Center(child: Text('Chưa có môn học nào'));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  final sub = subjects[index];
                  final count = docCountBySubject[sub.id] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: sub.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(Icons.school_rounded, color: sub.color, size: 24),
                        ),
                      ),
                      title: Text(
                        '${sub.code} - ${sub.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${sub.lecturer.isNotEmpty ? sub.lecturer : "Chưa cập nhật GV"} • $count tài liệu',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (val) {
                          if (val == 'view') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => DocumentListPage(
                                  initialFilter: DocumentFilter(subjectId: sub.id),
                                ),
                              ),
                            );
                          } else if (val == 'delete') {
                            _confirmDeleteSubject(context, sub, count);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.folder_open_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Xem tài liệu'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Xóa môn', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        // Mở danh sách tài liệu được lọc theo môn học này
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => DocumentListPage(
                              initialFilter: DocumentFilter(subjectId: sub.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context) {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final lecturerCtrl = TextEditingController();
    int selectedColor = 0xFF1E88E5;

    final availableColors = [
      0xFF1E88E5, // Blue
      0xFF7E57C2, // Purple
      0xFF00BFA5, // Teal
      0xFFFF7043, // Deep Orange
      0xFF43A047, // Green
      0xFFE91E63, // Pink
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thêm Môn học mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mã môn học *',
                    hintText: 'vd: CS101, SE301',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên môn học *',
                    hintText: 'vd: Kiến trúc Hệ thống',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lecturerCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Giảng viên',
                    hintText: 'vd: TS. Nguyễn Văn A',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Màu nhận diện:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: availableColors.map((c) {
                    final isSel = selectedColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSel
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSel
                              ? [BoxShadow(color: Color(c).withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newSub = Subject(
                  id: 'sub_${const Uuid().v4().substring(0, 8)}',
                  code: codeCtrl.text.trim().toUpperCase(),
                  name: nameCtrl.text.trim(),
                  lecturer: lecturerCtrl.text.trim(),
                  colorValue: selectedColor,
                  createdAt: DateTime.now(),
                );

                final validation = DocumentService.validateSubject(newSub);
                if (!validation.isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(validation.errors.values.first)),
                  );
                  return;
                }

                await database.insertSubject(newSub);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Thêm môn'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, Subject sub, int docCount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa môn học'),
        content: Text(
          'Xóa môn "${sub.name}" sẽ đồng thời xóa toàn bộ $docCount tài liệu liên kết với môn học này (Cascade Delete). Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await database.deleteSubject(sub.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xóa môn học và dữ liệu liên quan')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
