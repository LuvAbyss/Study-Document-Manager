import 'package:flutter/material.dart';
import '../struct/models.dart';
import '../colors.dart';

/// Modal Bottom Sheet lọc và sắp xếp theo phong cách Cashew
class FilterBottomSheet extends StatefulWidget {
  final DocumentFilter initialFilter;
  final List<Subject> subjects;
  final ValueChanged<DocumentFilter> onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.subjects,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required DocumentFilter initialFilter,
    required List<Subject> subjects,
    required ValueChanged<DocumentFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FilterBottomSheet(
        initialFilter: initialFilter,
        subjects: subjects,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late DocumentFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ lọc & Sắp xếp',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filter = const DocumentFilter();
                    });
                  },
                  child: const Text('Đặt lại'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Filter Options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SẮP XẾP THEO
                  _buildSectionTitle('Sắp xếp theo'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentSortOption.values.map((opt) {
                      final isSelected = _filter.sortOption == opt;
                      return ChoiceChip(
                        label: Text(opt.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _filter = _filter.copyWith(sortOption: opt));
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // LOẠI TÀI LIỆU
                  _buildSectionTitle('Loại tài liệu'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentType.values.map((type) {
                      final isSelected = _filter.type == type;
                      return FilterChip(
                        avatar: Icon(type.icon, size: 16, color: type.color),
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filter = selected
                                ? _filter.copyWith(type: type)
                                : _filter.copyWith(clearType: true);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // MÔN HỌC
                  if (widget.subjects.isNotEmpty) ...[
                    _buildSectionTitle('Môn học'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.subjects.map((sub) {
                        final isSelected = _filter.subjectId == sub.id;
                        return FilterChip(
                          avatar: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: sub.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          label: Text(sub.code),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _filter = selected
                                  ? _filter.copyWith(subjectId: sub.id)
                                  : _filter.copyWith(clearSubjectId: true);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // TRẠNG THÁI
                  _buildSectionTitle('Trạng thái xử lý'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DocumentStatus.values.map((status) {
                      final isSelected = _filter.status == status;
                      return FilterChip(
                        avatar: Icon(status.icon, size: 16, color: status.color),
                        label: Text(status.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filter = selected
                                ? _filter.copyWith(status: status)
                                : _filter.copyWith(clearStatus: true);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // MỨC ĐỘ ƯU TIÊN
                  _buildSectionTitle('Mức độ ưu tiên'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: Priority.values.map((p) {
                      final isSelected = _filter.priority == p;
                      return FilterChip(
                        avatar: Icon(Icons.flag_rounded, size: 16, color: p.color),
                        label: Text(p.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _filter = selected
                                ? _filter.copyWith(priority: p)
                                : _filter.copyWith(clearPriority: true);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // TÙY CHỌN BỔ SUNG (SWITCHES)
                  _buildSectionTitle('Tùy chọn khác'),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ hiện tài liệu Yêu thích (Đánh dấu sao)'),
                    value: _filter.onlyFavorites == true,
                    onChanged: (val) {
                      setState(() {
                        _filter = _filter.copyWith(onlyFavorites: val ? true : false);
                      });
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Chỉ hiện tài liệu có Hạn chót (Deadline)'),
                    value: _filter.onlyHasDueDate == true,
                    onChanged: (val) {
                      setState(() {
                        _filter = _filter.copyWith(onlyHasDueDate: val ? true : false);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Nút Áp dụng ở đáy
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_filter);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Áp dụng bộ lọc',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
