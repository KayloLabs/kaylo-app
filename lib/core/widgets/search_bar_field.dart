import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'kaylo_logo.dart';

class SearchBarField extends StatelessWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;

  const SearchBarField({
    super.key,
    this.hintText = 'Search services...',
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      style: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        filled: false,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(
            Icons.search,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        suffixIcon: controller?.text.isNotEmpty == true 
          ? IconButton(
              icon: Icon(Icons.clear, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              onPressed: () {
                controller?.clear();
                onChanged?.call('');
              },
            )
          : null,
      ),
    );
  }
}
