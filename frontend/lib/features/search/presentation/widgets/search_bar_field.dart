import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Pinned, rounded search field with a focus animation and a clear button.
/// Debouncing is the view model's job, not this widget's — [onChanged] fires
/// on every keystroke so the field's own state (the clear button) stays
/// instantly responsive.
class SearchBarField extends StatefulWidget {
  const SearchBarField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<SearchBarField> createState() => _SearchBarFieldState();
}

class _SearchBarFieldState extends State<SearchBarField> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppColors.pink : Colors.white.withValues(alpha: 0.08),
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.pink.withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        style: const TextStyle(color: AppColors.textLight, fontSize: 15),
        decoration: InputDecoration(
          filled: false,
          isDense: true,
          hintText: 'Search users',
          hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.5)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(Icons.search, color: AppColors.textLight.withValues(alpha: 0.6)),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textLight.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  onPressed: widget.onClear,
                ),
        ),
      ),
    );
  }
}
