import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../struct/models.dart';
import '../struct/document_service.dart';
import '../database/database_global.dart';
import '../colors.dart';

/// Màn hình Thêm mới hoặc Chỉnh sửa Tài liệu học tập (Add / Edit Document Page)
class AddEditDocumentPage extends StatefulWidget {
  final StudyDocument? initialDocument;
  final String? preselectedSubjectId;

  const AddEditDocumentPage({
    super.key,
    this.initialDocument,
    this.preselectedSubjectId,
  });

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _fileUrlController;
  late TextEditingController _tagsController;

  late DocumentType _selectedType;
  late DocumentStatus _selectedStatus;
  late Priority _selectedPriority;
  String? _selectedSubjectId;
  DateTime? _dueDate;
  String _fileType = 'PDF';
  bool _isFavorite = false;

  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get isEditing => widget.initialDocument != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;

    _titleController = TextEditingController(text: doc?.title ?? '');
    _descriptionController = TextEditingController(text: doc?.description ?? '');
    _fileUrlController = TextEditingController(text: doc?.fileUrl ?? '');
    _tagsController = TextEditingController(text: doc?.tags.join(', ') ?? '');

    _selectedType = doc?.type ?? DocumentType.lecture;
    _selectedStatus = doc?.status ?? DocumentStatus.pending;
    _selectedPriority = doc?.priority ?? Priority.medium;
    _selectedSubjectId = doc?.subjectId ?? widget.preselectedSubjectId;
    _dueDate = doc?.dueDate;
    _fileType = doc?.fileType ?? 'PDF';
    _isFavorite = doc?.isFavorite ?? false;

    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final subjects = await database.getAllSubjects();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        if (_selectedSubjectId == null && subjects.isNotEmpty) {
          _selectedSubjectId = subjects.first.id;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveDocument() async {
    setState(() => _errorMessage = null);

    final rawTags = _tagsController.text
        .split(',')
        .map((t) => t.trim().replaceAll('#', ''))
        .where((t) => t.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final docId = widget.initialDocument?.id ?? const Uuid().v4();

    final newDoc = StudyDocument(
      id: docId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      subjectId: _selectedSubjectId ?? '',
      type: _selectedType,
      status: _selectedStatus,
      priority: _selectedPriority,
      fileUrl: _fileUrlController.text.trim(),
      fileType: _fileType,
      fileSizeBytes: widget.initialDocument?.fileSizeBytes ?? 0,
      dueDate: _dueDate,
      isFavorite: _isFavorite,
      tags: rawTags,
      createdAt: widget.initialDocument?.createdAt ?? now,
      updatedAt: now,
    );

    // Xác thực dữ liệu qua Business Logic Layer
    final validation = DocumentService.validateDocument(newDoc);
    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.errors.values.first;
      });
      return;
    }

    try {
      if (isEditing) {
        await database.updateDocument(newDoc);
      } else {
        await database.insertDocument(newDoc);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Đã cập nhật tài liệu thành công' : 'Đã thêm tài liệu mới',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi lưu trữ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? AppColors.accentAmber : null,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_rounded),
            onPressed: _saveDocument,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thông báo lỗi nếu có
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. TIÊU ĐỀ TÀI LIỆU
              _buildSectionHeader('Tiêu đề tài liệu *'),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên slide, đề cương hoặc bài tập...',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 2. MÔN HỌC LIÊN KẾT
              _buildSectionHeader('Môn học liên kết *'),
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                items: _subjects.map((sub) {
                  return DropdownMenuItem<String>(
                    value: sub.id,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: sub.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${sub.code} - ${sub.name}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedSubjectId = val);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. LOẠI TÀI LIỆU (Lecture, Assignment, Reference, Exam)
              _buildSectionHeader('Loại tài liệu'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DocumentType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return ChoiceChip(
                    avatar: Icon(type.icon, size: 16, color: type.color),
                    label: Text(type.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedType = type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 4. MỨC ĐỘ ƯU TIÊN
              _buildSectionHeader('Mức độ ưu tiên'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Priority.values.map((p) {
                  final isSelected = _selectedPriority == p;
                  return ChoiceChip(
                    avatar: Icon(Icons.flag_rounded, size: 16, color: p.color),
                    label: Text(p.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedPriority = p);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 5. TRẠNG THÁI HIỆN TẠI
              _buildSectionHeader('Trạng thái'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DocumentStatus.values.map((s) {
                  final isSelected = _selectedStatus == s;
                  return ChoiceChip(
                    avatar: Icon(s.icon, size: 16, color: s.color),
                    label: Text(s.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedStatus = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // 6. HẠN NỘP / DEADLINE (Nếu có)
              _buildSectionHeader('Hạn hoàn thành (Deadline)'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      color: _dueDate != null ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dueDate != null
                            ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                            : 'Không có hạn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _dueDate != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_dueDate != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _dueDate = null),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 3)),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _dueDate = picked);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
              ),
              // Phím tắt chọn nhanh ngày
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    _buildQuickDateChip('+1 ngày', const Duration(days: 1)),
                    const SizedBox(width: 8),
                    _buildQuickDateChip('+3 ngày', const Duration(days: 3)),
                    const SizedBox(width: 8),
                    _buildQuickDateChip('+1 tuần', const Duration(days: 7)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7. LIÊN KẾT / ĐƯỜNG DẪN TÀI LIỆU
              _buildSectionHeader('Đường dẫn tệp tin hoặc URL'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fileUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://drive.google.com/... hoặc đường dẫn file',
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _fileType,
                    items: ['PDF', 'URL', 'ZIP', 'DOCX', 'PPTX'].map((t) {
                      return DropdownMenuItem<String>(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _fileType = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 8. THẺ NHÃN (TAGS)
              _buildSectionHeader('Thẻ phân loại (#tags cách nhau bởi dấu phẩy)'),
              TextField(
                controller: _tagsController,
                decoration: InputDecoration(
                  hintText: 'architecture, exam, midterm, chapter1',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 9. GHI CHÚ / MÔ TẢ
              _buildSectionHeader('Ghi chú / Tóm tắt nội dung'),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập các lưu ý quan trọng, trọng tâm cần ôn...',
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // NÚT LƯU Ở ĐÁY FORM
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveDocument,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(
                    isEditing ? 'LƯU THAY ĐỔI' : 'TẠO TÀI LIỆU',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, Duration duration) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () {
        setState(() {
          _dueDate = DateTime.now().add(duration);
        });
      },
    );
  }
}
