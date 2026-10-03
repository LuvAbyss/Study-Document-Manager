import 'package:flutter/material.dart';
import '../struct/models.dart';
import '../database/database_global.dart';
import '../widgets/document_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/empty_state.dart';
import 'add_edit_document_page.dart';
import 'document_detail_page.dart';

/// Màn hình Danh sách Tài liệu học tập (Document List Page)
class DocumentListPage extends StatefulWidget {
  final DocumentFilter initialFilter;

  const DocumentListPage({
    super.key,
    this.initialFilter = const DocumentFilter(),
  });

  @override
  State<DocumentListPage> createState() => _DocumentListPageState();
}

class _DocumentListPageState extends State<DocumentListPage> {
  late DocumentFilter _filter;
  late TextEditingController _searchController;
  Map<String, Subject> _subjectMap = {};
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController = TextEditingController(text: _filter.searchQuery ?? '');
    _loadSubjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    final subs = await database.getAllSubjects();
    if (mounted) {
      setState(() {
        _subjects = subs;
        _subjectMap = {for (var s in subs) s.id: s};
      });
    }
  }

  void _openFilterSheet() {
    FilterBottomSheet.show(
      context: context,
      initialFilter: _filter,
      subjects: _subjects,
      onApply: (newFilter) {
        setState(() {
          _filter = newFilter.copyWith(searchQuery: _searchController.text);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kho tài liệu học tập'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddEditDocumentPage()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
      ),
      body: Column(
        children: [
          // 1. Thanh tìm kiếm
          SearchBarWidget(
            controller: _searchController,
            hasActiveFilters: _filter.isActive,
            onChanged: (query) {
              setState(() {
                _filter = _filter.copyWith(searchQuery: query);
              });
            },
            onFilterTap: _openFilterSheet,
            onClear: () {
              setState(() {
                _filter = _filter.copyWith(clearSearchQuery: true);
              });
            },
          ),

          // 2. Thanh phân loại nhanh (Quick Filter Chips)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildQuickChip(
                  label: 'Tất cả',
                  isSelected: _filter.type == null && _filter.priority == null,
                  onSelected: () => setState(() => _filter = _filter.copyWith(
                        clearType: true,
                        clearPriority: true,
                      )),
                ),
                const SizedBox(width: 8),
                ...DocumentType.values.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildQuickChip(
                      label: t.displayName,
                      icon: t.icon,
                      isSelected: _filter.type == t,
                      onSelected: () => setState(() => _filter = _filter.copyWith(
                            type: _filter.type == t ? null : t,
                            clearType: _filter.type == t,
                          )),
                    ),
                  );
                }),
                _buildQuickChip(
                  label: 'Khẩn cấp',
                  icon: Icons.warning_amber_rounded,
                  isSelected: _filter.priority == Priority.urgent,
                  onSelected: () => setState(() => _filter = _filter.copyWith(
                        priority: _filter.priority == Priority.urgent ? null : Priority.urgent,
                        clearPriority: _filter.priority == Priority.urgent,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // 3. Danh sách tài liệu phản ứng (Reactive StreamBuilder)
          Expanded(
            child: StreamBuilder<List<StudyDocument>>(
              stream: database.watchDocumentsWithFilter(_filter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data ?? [];

                if (docs.isEmpty) {
                  return EmptyStateWidget(
                    icon: _filter.isActive
                        ? Icons.filter_alt_off_rounded
                        : Icons.folder_open_rounded,
                    title: _filter.isActive
                        ? 'Không tìm thấy kết quả phù hợp'
                        : 'Chưa có tài liệu nào',
                    message: _filter.isActive
                        ? 'Thử điều chỉnh lại từ khóa hoặc xóa bớt tiêu chí lọc.'
                        : 'Nhấn nút "+" bên dưới để thêm bài giảng, bài tập hoặc tài liệu mới.',
                    buttonText: _filter.isActive ? 'Xóa bộ lọc' : 'Thêm tài liệu ngay',
                    onButtonPressed: () {
                      if (_filter.isActive) {
                        setState(() {
                          _filter = const DocumentFilter();
                          _searchController.clear();
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const AddEditDocumentPage()),
                        );
                      }
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 4),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final subject = _subjectMap[doc.subjectId];

                    return DocumentCard(
                      document: doc,
                      subject: subject,
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
                      onDelete: () => _deleteDocument(doc),
                      onToggleFavorite: () => database.toggleFavorite(doc.id),
                      onStatusChanged: (status) =>
                          database.updateDocumentStatus(doc.id, status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 16) : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }

  void _deleteDocument(StudyDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc muốn xóa "${doc.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await database.deleteDocument(doc.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã xóa tài liệu'),
                    action: SnackBarAction(
                      label: 'Hoàn tác',
                      onPressed: () => database.insertDocument(doc),
                    ),
                  ),
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
