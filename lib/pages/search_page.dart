import 'package:flutter/material.dart';
import '../struct/models.dart';
import '../database/database_global.dart';
import '../widgets/document_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/empty_state.dart';
import 'document_detail_page.dart';
import 'add_edit_document_page.dart';

/// Màn hình Tìm kiếm Nâng cao Thời gian thực (Search Page)
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  DocumentFilter _filter = const DocumentFilter();
  Map<String, Subject> _subjectMap = {};

  final List<String> _suggestedTags = [
    'architecture',
    'assignment',
    'midterm',
    'slides',
    'flutter',
    'database',
  ];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subs = await database.getAllSubjects();
    if (mounted) {
      setState(() {
        _subjectMap = {for (var s in subs) s.id: s};
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tìm kiếm tài liệu'),
      ),
      body: Column(
        children: [
          SearchBarWidget(
            controller: _controller,
            hasActiveFilters: _filter.isActive,
            onChanged: (val) {
              setState(() {
                _filter = _filter.copyWith(searchQuery: val);
              });
            },
            onClear: () {
              setState(() {
                _filter = _filter.copyWith(clearSearchQuery: true);
              });
            },
          ),

          // Gợi ý từ khóa & tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Gợi ý: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _suggestedTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            label: Text('#$tag', style: const TextStyle(fontSize: 11)),
                            onPressed: () {
                              _controller.text = tag;
                              setState(() {
                                _filter = _filter.copyWith(searchQuery: tag);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 16),

          // Kết quả tìm kiếm
          Expanded(
            child: StreamBuilder<List<StudyDocument>>(
              stream: database.watchDocumentsWithFilter(_filter),
              builder: (context, snapshot) {
                final docs = snapshot.data ?? [];

                if (_controller.text.isEmpty && !_filter.isActive) {
                  return const EmptyStateWidget(
                    icon: Icons.search_rounded,
                    title: 'Tìm kiếm tài liệu học tập',
                    message: 'Nhập từ khóa theo tiêu đề, ghi chú, mã môn học hoặc thẻ #tag.',
                  );
                }

                if (docs.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'Không tìm thấy tài liệu',
                    message: 'Không có tài liệu nào khớp với từ khóa "${_controller.text}".',
                  );
                }

                return ListView.builder(
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
                      onDelete: () => database.deleteDocument(doc.id),
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
}
