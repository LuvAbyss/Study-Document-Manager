import 'package:flutter/material.dart';
import '../cloud/rls_policy_engine.dart';
import '../colors.dart';
import '../database/database_global.dart';
import '../struct/document_service.dart';
import '../struct/models.dart';

/// Bottom Sheet Chia sẻ & Quản lý Phân quyền Tài liệu (Supabase `permissions` + RLS)
class ShareDocumentSheet extends StatefulWidget {
  final StudyDocument document;

  const ShareDocumentSheet({
    super.key,
    required this.document,
  });

  static Future<void> show(BuildContext context, StudyDocument document) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareDocumentSheet(document: document),
    );
  }

  @override
  State<ShareDocumentSheet> createState() => _ShareDocumentSheetState();
}

class _ShareDocumentSheetState extends State<ShareDocumentSheet> {
  final TextEditingController _emailController = TextEditingController();
  PermissionLevel _selectedLevel = PermissionLevel.viewer;
  String? _errorText;
  String? _successText;
  List<AppUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await database.getAllUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleShare() async {
    setState(() {
      _errorText = null;
      _successText = null;
    });

    final currentUser = database.currentUser;
    final validation = DocumentService.validateShareRequest(
      targetEmail: _emailController.text,
      currentUserEmail: currentUser?.email ?? widget.document.ownerEmail,
    );

    if (!validation.isValid) {
      setState(() {
        _errorText = validation.errors.values.first;
      });
      return;
    }

    try {
      final perm = await database.shareDocument(
        documentId: widget.document.id,
        targetEmail: _emailController.text.trim(),
        permissionLevel: _selectedLevel,
      );
      _emailController.clear();
      if (mounted) {
        setState(() {
          _successText =
              'Đã cấp quyền "${perm.permissionLevel.shortLabel}" cho ${perm.sharedWithEmail}';
        });
      }
    } on RlsAccessDeniedException catch (e) {
      setState(() => _errorText = e.message);
    } catch (e) {
      setState(() => _errorText = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePermission = database.getEffectivePermission(widget.document.id);
    final canManage = effectivePermission.canManagePermissions;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            children: [
              // Thanh kéo
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề Sheet
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chia sẻ & Phân quyền Truy cập',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.document.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: effectivePermission.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          effectivePermission.icon,
                          size: 14,
                          color: effectivePermission.color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          effectivePermission.shortLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: effectivePermission.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Thông báo lỗi / thành công
              if (_errorText != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security_rounded, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: const TextStyle(color: Colors.red, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_successText != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusCompleted.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.statusCompleted,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successText!,
                          style: const TextStyle(
                            color: AppColors.statusCompleted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Khối nhập Email & Chọn quyền (Chỉ Owner được phép thao tác theo RLS)
              if (canManage) ...[
                const Text(
                  'Thêm người dùng nhận chia sẻ (Google Email)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('share_email_input'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Nhập email (vd: binh.tran@edu.vn)...',
                          isDense: true,
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: DropdownButton<PermissionLevel>(
                          value: _selectedLevel,
                          items: const [
                            DropdownMenuItem(
                              value: PermissionLevel.viewer,
                              child: Text('Chỉ xem', style: TextStyle(fontSize: 13)),
                            ),
                            DropdownMenuItem(
                              value: PermissionLevel.editor,
                              child: Text('Được sửa', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedLevel = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Gợi ý chọn nhanh từ danh sách tài khoản Google trong hệ thống
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _allUsers
                      .where((u) => u.uid != widget.document.ownerUid)
                      .map((user) {
                    return ActionChip(
                      avatar: CircleAvatar(
                        backgroundColor: user.avatarColor,
                        child: Text(
                          user.initials,
                          style: const TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                      label: Text(
                        '${user.displayName} (${user.email})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () {
                        setState(() {
                          _emailController.text = user.email;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('confirm_share_button'),
                    onPressed: _handleShare,
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: const Text(
                      'CẤP QUYỀN TRUY CẬP TRÊN SUPABASE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const Divider(height: 28),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Chính sách bảo mật Supabase RLS: Chỉ Chủ sở hữu (${widget.document.ownerName}) mới có quyền thêm hoặc thay đổi danh sách chia sẻ.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Danh sách người có quyền truy cập
              const Text(
                'Danh sách phân quyền hiện tại (Bảng `permissions`)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // 1. Chủ sở hữu gốc (Owner)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: PermissionLevel.owner.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: PermissionLevel.owner.color,
                      child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.ownerName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            widget.document.ownerEmail,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PermissionLevel.owner.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Chủ sở hữu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: PermissionLevel.owner.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Danh sách người dùng được chia sẻ (Stream từ database)
              StreamBuilder<List<DocumentPermission>>(
                stream: database.watchPermissionsForDocument(widget.document.id),
                builder: (context, snapshot) {
                  final perms = snapshot.data ?? [];
                  if (perms.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Tài liệu này đang ở chế độ Riêng tư (chưa chia sẻ cho ai).',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: perms.map((perm) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: perm.permissionLevel.color.withValues(alpha: 0.2),
                              child: Icon(
                                perm.permissionLevel.icon,
                                color: perm.permissionLevel.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    perm.sharedWithName.isNotEmpty
                                        ? perm.sharedWithName
                                        : perm.sharedWithEmail,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  Text(
                                    perm.sharedWithEmail,
                                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            if (canManage) ...[
                              DropdownButton<PermissionLevel>(
                                value: perm.permissionLevel,
                                underline: const SizedBox.shrink(),
                                items: const [
                                  DropdownMenuItem(
                                    value: PermissionLevel.viewer,
                                    child: Text('Chỉ xem', style: TextStyle(fontSize: 12)),
                                  ),
                                  DropdownMenuItem(
                                    value: PermissionLevel.editor,
                                    child: Text('Được sửa', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                                onChanged: (newLevel) async {
                                  if (newLevel != null && newLevel != perm.permissionLevel) {
                                    await database.updatePermissionLevel(
                                      permissionId: perm.id,
                                      newLevel: newLevel,
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                tooltip: 'Thu hồi quyền truy cập',
                                onPressed: () async {
                                  await database.revokePermission(perm.id);
                                },
                              ),
                            ] else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: perm.permissionLevel.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  perm.permissionLevel.shortLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: perm.permissionLevel.color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
