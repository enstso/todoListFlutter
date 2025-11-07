import 'package:flutter/material.dart';
import 'package:todo_list/models/task_model.dart';

class CategoryFilter extends StatelessWidget {
  final TaskCategory? selectedCategory;
  final Function(TaskCategory?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _CategoryChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),
          ...TaskCategory.values.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: category.displayName,
                  color: category.color,
                  isSelected: selectedCategory == category,
                  onTap: () => onCategorySelected(category),
                ),
              )),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: color?.withValues(alpha:0.1 ),
      selectedColor: color?.withValues(alpha: 0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }
}