import 'package:flutter/material.dart';
import '../cloud/cloud_config.dart';
import '../colors.dart';
import '../database/database_global.dart';
import '../struct/models.dart';

/// Màn hình Quản lý Tài khoản Google (Firebase Auth), Cấu trúc Cloud (Supabase + Storage)
/// và Trình chuyển đổi Đa Tài khoản kiểm chứng Row Level Security (RLS).
class CloudAccountPage extends StatefulWidget {
  const CloudAccountPage({super.key});

  @override
  State<CloudAccountPage> createState() => _CloudAccountPageState();
}

class _CloudAccountPageState extends State<CloudAccountPage> {
  String? _statusBanner;

  Future<void> _switchAccount(AppUser user) async {
    await database.setCurrentUser(user.uid);
    if (mounted) {
      setState(() {
        _statusBanner =
            'Đã chuyển phiên Google Auth sang: ${user.displayName} (${user.email})';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã đăng nhập: ${user.displayName} • Áp dụng chính sách RLS cho ${user.email}',
          ),
          backgroundColor: user.avatarColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Auth & Phân quyền RLS'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: database.watchCurrentUser(),
        builder: (context, userSnap) {
          final currentUser = userSnap.data ?? database.currentUser;

          return StreamBuilder<List<AppUser>>(
            stream: database.watchAllUsers(),
            builder: (context, allUsersSnap) {
              final allUsers = allUsersSnap.data ?? [];

              return StreamBuilder<List<StudyDocument>>(
                stream: database.watchAllDocuments(),
                builder: (context, docsSnap) {
                  final accessibleDocs = docsSnap.data ?? [];

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: [
                      // 1. Thẻ tài khoản Google đang đăng nhập (Firebase Auth + Supabase Users)
                      _buildActiveAccountCard(context, currentUser, accessibleDocs, isDark),
                      const SizedBox(height: 16),

                      if (_statusBanner != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _statusBanner!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 2. Bộ chuyển đổi nhanh Đa Tài khoản Google (Kiểm thử >= 3 tài khoản)
                      const Text(
                        'Chuyển đổi Tài khoản Google (Kiểm thử Đa Tài khoản RLS)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chọn một trong 4 tài khoản Google dưới đây để kiểm chứng dữ liệu và quyền hạn thay đổi tức thì theo chính sách Row Level Security (RLS).',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...allUsers.map((user) {
                        final isSelected = currentUser?.uid == user.uid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? user.avatarColor
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              key: Key('switch_account_${user.uid}'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onTap: () => _switchAccount(user),
                              leading: CircleAvatar(
                                backgroundColor: user.avatarColor,
                                child: Text(
                                  user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.avatarColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Đang đăng nhập',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: user.avatarColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    '${user.email} • UID: ${user.uid}',
                                    style: const TextStyle(fontSize: 11.5),
                                  ),
                                  Text(
                                    user.roleTitle,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: user.avatarColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.login_rounded,
                                color: isSelected ? user.avatarColor : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // 3. Thẻ Kiến trúc Hệ sinh thái Cloud (Firebase + Supabase)
                      _buildCloudArchitectureStatusCard(isDark),
                      const SizedBox(height: 20),

                      // 4. Bảng tổng hợp quyền của tài khoản hiện tại trên các tài liệu được phép truy cập
                      Text(
                        'Tài liệu được phép truy cập của ${currentUser?.displayName ?? ""} (${accessibleDocs.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...accessibleDocs.map((doc) {
                        final level = database.getEffectivePermission(doc.id);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(level.icon, color: level.color, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Chủ sở hữu: ${doc.ownerName} • Storage: ${doc.fileName.isNotEmpty ? doc.fileName : "URL"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: level.color.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  level.shortLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: level.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveAccountCard(
    BuildContext context,
    AppUser? user,
    List<StudyDocument> accessibleDocs,
    bool isDark,
  ) {
    if (user == null) {
      return const SizedBox.shrink();
    }

    final ownedCount = accessibleDocs.where((d) => d.ownerUid == user.uid).length;
    final sharedCount = accessibleDocs.length - ownedCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            user.avatarColor,
            user.avatarColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                child: Text(
                  user.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GOOGLE AUTH • SUPABASE RLS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBadge('Được xem (RLS)', '${accessibleDocs.length}'),
                _buildStatBadge('Sở hữu (Owner)', '$ownedCount'),
                _buildStatBadge('Được chia sẻ', '$sharedCount'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildCloudArchitectureStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Cấu hình Hạ tầng Cloud & Bảo mật',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInfraRow(
            'Xác thực (Auth):',
            'Firebase Authentication (Google Sign-In Provider)',
          ),
          const SizedBox(height: 6),
          _buildInfraRow(
            'Lưu trữ vật lý:',
            '${CloudConfig.firebaseStorageBucket}/users/{uid}/subjects/{subId}/documents/{docId}/',
          ),
          const SizedBox(height: 6),
          _buildInfraRow(
            'CSDL Quan hệ:',
            'Supabase PostgreSQL (Bảng: users, subjects, documents, permissions)',
          ),
          const SizedBox(height: 6),
          _buildInfraRow(
            'Bảo mật (RLS):',
            'Đang bật Row Level Security (Owner / Editor / Viewer)',
          ),
        ],
      ),
    );
  }

  Widget _buildInfraRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
