import 'package:flutter/material.dart';
import '../colors.dart';

/// Thanh tìm kiếm và bộ lọc nhanh (Search Bar Widget)
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final bool hasActiveFilters;
  final String hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFilterTap,
    this.onClear,
    this.hasActiveFilters = false,
    this.hintText = 'Tìm kiếm tài liệu, môn học, #tag...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveFilters
              ? AppColors.primary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: hasActiveFilters ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, color: Colors.grey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
              onPressed: () {
                controller.clear();
                onClear?.call();
                onChanged?.call('');
              },
            ),
          if (onFilterTap != null) ...[
            Container(
              height: 24,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: hasActiveFilters ? AppColors.primary : Colors.grey,
                  ),
                  onPressed: onFilterTap,
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
