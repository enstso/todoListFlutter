import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/pages/viewmodels/add_task_view_model.dart';

class AddTaskSheet extends StatelessWidget {
  const AddTaskSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddTaskViewModel(),
      child: const _AddTaskSheetBody(),
    );
  }
}

class _AddTaskSheetBody extends StatelessWidget {
  const _AddTaskSheetBody();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddTaskViewModel>();
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
          Text('New task', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),

          TextField(
            controller: vm.titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Ex: Buy milk',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: vm.descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Details (optional)',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          Text('Category', style: Theme.of(context).textTheme.titleSmall),
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
                    selected: vm.selectedCategory == category,
                    onSelected: (_) => vm.setCategory(category),
                    backgroundColor: category.color.withValues(alpha: 0.1),
                    selectedColor: category.color.withValues(alpha: 0.3),
                    checkmarkColor: category.color,
                    labelStyle: TextStyle(
                      color: vm.selectedCategory == category
                          ? category.color
                          : null,
                      fontWeight: vm.selectedCategory == category
                          ? FontWeight.w600
                          : null,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 16),

          Text('Tags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: vm.tagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add a tag',
                    hintText: 'Ex: urgent, important, etc.',
                    prefixIcon: Icon(Icons.tag),
                    suffixIcon: Icon(Icons.add),
                  ),
                  onSubmitted: vm.addTag,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => vm.addTag(vm.tagCtrl.text),
                icon: const Icon(Icons.add_circle),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                ),
              ),
            ],
          ),
          if (vm.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: vm.tags
                  .map(
                    (tag) => Chip(
                      label: Text('#$tag'),
                      onDeleted: () => vm.removeTag(tag),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  )
                  .toList(),
            ),
          ],

          const SizedBox(height: 20),
          Text('Photo', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          if (vm.imageBytes == null)
            OutlinedButton.icon(
              onPressed: vm.pickImage,
              icon: const Icon(Icons.photo),
              label: const Text('Add a photo'),
            )
          else
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    vm.imageBytes!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: vm.clearImage,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove photo'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: vm.pickImage,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Change photo'),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final service = context.read<TaskService>();
                    final title = vm.titleCtrl.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }

                    await service.addTask(
                      TaskModel(
                        id: '_',
                        userId: '_',
                        title: title,
                        description: vm.descCtrl.text.trim(),
                        isCompleted: false,
                        createdAt: DateTime.now(),
                        category: vm.selectedCategory,
                        tags: vm.tags,
                        imageUrl: null,
                      ),
                      imageBytes: vm.imageBytes,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task "$title" added'),
                        backgroundColor: vm.selectedCategory.color,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ],
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
