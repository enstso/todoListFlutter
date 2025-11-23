import 'package:flutter/material.dart';
import 'package:todo_list/models/task_model.dart';

// Horizontal category selector displayed at the top of the TasksPage.
// Allows users to quickly filter tasks by category.
class CategoryFilter extends StatelessWidget {
  // Currently selected category (null = All)
  final TaskCategory? selectedCategory;

  // Callback executed when the user selects a category
  final Function(TaskCategory?) onCategorySelected;

  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50, // Fixed height for the horizontal list
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal, // Makes chips scroll horizontally
        children: [
          // "All" category (clears selection)
          _CategoryChip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 8),

          // One chip per category defined in the enum
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

// Small reusable FilterChip representing one category.
class _CategoryChip extends StatelessWidget {
  final String label;
  final Color? color; // Category color (optional for "All")
  final bool isSelected; // Whether this chip is currently selected
  final VoidCallback onTap; // Called when user taps the chip

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
      onSelected: (_) => onTap(), // Trigger selection handler
      backgroundColor: color?.withValues(alpha: 0.1), // Light color background
      selectedColor: color?.withValues(alpha: 0.3), // Highlight on selected
      checkmarkColor: color, // Check icon matches category color
      labelStyle: TextStyle(
        color: isSelected ? color : null, // Highlight label when selected
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }
}
