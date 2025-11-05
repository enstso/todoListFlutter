import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  TaskCategory selectedCategory = TaskCategory.other;
  final List<String> tags = [];

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SheetHandle(),
          const SizedBox(height: 8),
          Text('Nouvelle tâche', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          // Title Field
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Acheter du lait',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          // Description Field
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Détails (optionnel)',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Category Selection
          Text('Catégorie', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TaskCategory.values
                .map(
                  (category) => FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(category.displayName),
                      ],
                    ),
                    selected: selectedCategory == category,
                    onSelected: (_) =>
                        setState(() => selectedCategory = category),
                    backgroundColor: category.color.withValues(alpha: 0.1),
                    selectedColor: category.color.withValues(alpha: 0.3),
                    checkmarkColor: category.color,
                    labelStyle: TextStyle(
                      color: selectedCategory == category
                          ? category.color
                          : null,
                      fontWeight: selectedCategory == category
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Tags Section
          Text('Tags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          // Tag Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add a tag',
                    hintText: 'Ex: urgent, important, etc.',
                    prefixIcon: Icon(Icons.tag),
                    suffixIcon: Icon(Icons.add),
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _addTag(tagCtrl.text),
                icon: const Icon(Icons.add_circle),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              ),
            ],
          ),

          // Display Tags
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _addTask,
                  child: const Text('Ajouter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !tags.contains(trimmedTag)) {
      setState(() {
        tags.add(trimmedTag);
        tagCtrl.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
  }

  void _addTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final service = context.read<TaskService>();
    await service.addTask(
      TaskModel(
        id: '_', 
        userId: '_', 
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        isCompleted: false,
        createdAt: DateTime.now(),
        category: selectedCategory, 
        tags: tags,
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tâche "${titleCtrl.text.trim()}" ajoutée'),
        backgroundColor: selectedCategory.color,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
