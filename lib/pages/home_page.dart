import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../struct/models.dart';
import '../struct/document_service.dart';
import '../struct/settings.dart';
import '../database/database_global.dart';
import '../widgets/summary_card.dart';
import '../widgets/document_card.dart';
import '../colors.dart';
import 'document_list_page.dart';
import 'subjects_page.dart';
import 'search_page.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';

/// Màn hình chính của ứng dụng (Cashew Navigation Framework & Home Dashboard)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<AppSettings>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pages = [
      _buildDashboardTab(context, isDark, settings),
      const DocumentListPage(),
      const SubjectsPage(),
      const SearchPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder_rounded),
            label: 'Tài liệu',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: 'Môn học',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Tìm kiếm',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(
    BuildContext context,
    bool isDark,
    AppSettings settings,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cashew StudyDocs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              'Học kỳ 1 • 2026-2027',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Nút chuyển đổi Dark/Light mode
          IconButton(
            icon: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Đổi giao diện sáng/tối',
            onPressed: () {
              settings.setThemeMode(
                settings.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          // Nút reset dữ liệu mẫu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'reset') {
                await database.resetToSampleData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã khôi phục dữ liệu mẫu')),
                  );
                }
              } else if (val == 'clear') {
                await database.clearAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa toàn bộ tài liệu')),
                  );
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Khôi phục dữ liệu mẫu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa sạch dữ liệu', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddEditDocumentPage()),
          );
        },
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: StreamBuilder<List<Subject>>(
        stream: database.watchAllSubjects(),
        builder: (context, subjectSnapshot) {
          final subjects = subjectSnapshot.data ?? [];
          final subjectMap = {for (var s in subjects) s.id: s};

          return StreamBuilder<List<StudyDocument>>(
            stream: database.watchAllDocuments(),
            builder: (context, docSnapshot) {
              final documents = docSnapshot.data ?? [];

              // Tính toán thống kê nghiệp vụ qua Struct Service
              final stats = DocumentService.computeStatistics(documents, subjects);

              // Danh sách bài tập sắp đến hạn hoặc khẩn cấp
              final urgentDocs = documents
                  .where((d) =>
                      d.status != DocumentStatus.completed &&
                      (d.priority == Priority.urgent || d.isOverdue || (d.daysUntilDue != null && d.daysUntilDue! <= 3)))
                  .toList();

              // Danh sách tài liệu thêm gần đây
              final recentDocs = List<StudyDocument>.from(documents)
                ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
              final topRecent = recentDocs.take(5).toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 300));
                  setState(() {});
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 90),
                  children: [
                    // 1. Khối KPI & Thống kê
                    DashboardSummarySection(
                      statistics: stats,
                      onPendingAssignmentsTap: () {
                        setState(() => _currentIndex = 1); // Chuyển sang tab tài liệu
                      },
                      onUrgentTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),

                    // 2. Phần: Cần chú ý / Hạn chót sắp tới
                    if (urgentDocs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppColors.priorityUrgent, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Cần chú ý & Hạn chót sắp tới',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.priorityUrgent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${urgentDocs.length}',
                                style: const TextStyle(
                                  color: AppColors.priorityUrgent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...urgentDocs.map((doc) {
                        return DocumentCard(
                          document: doc,
                          subject: subjectMap[doc.subjectId],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => DocumentDetailPage(documentId: doc.id),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => AddEditDocumentPage(initialDocument: doc),
                              ),
                            );
                          },
                          onDelete: () => database.deleteDocument(doc.id),
                          onToggleFavorite: () => database.toggleFavorite(doc.id),
                          onStatusChanged: (status) =>
                              database.updateDocumentStatus(doc.id, status),
                        );
                      }),
                    ],

                    // 3. Phần: Tài liệu gần đây
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tài liệu cập nhật gần đây',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _currentIndex = 1);
                            },
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                    ),
                    if (topRecent.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('Chưa có tài liệu nào')),
                      )
                    else
                      ...topRecent.map((doc) {
                        return DocumentCard(
                          document: doc,
                          subject: subjectMap[doc.subjectId],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => DocumentDetailPage(documentId: doc.id),
                              ),
                            );
                          },
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => AddEditDocumentPage(initialDocument: doc),
                              ),
                            );
                          },
                          onDelete: () => database.deleteDocument(doc.id),
                          onToggleFavorite: () => database.toggleFavorite(doc.id),
                          onStatusChanged: (status) =>
                              database.updateDocumentStatus(doc.id, status),
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
