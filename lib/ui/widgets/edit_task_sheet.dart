import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/pages/viewmodels/edit_task_view_model.dart';

class EditTaskSheet extends StatelessWidget {
  final TaskModel task;

  const EditTaskSheet({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditTaskViewModel(task),
      child: const _EditTaskSheetBody(),
    );
  }
}

class _EditTaskSheetBody extends StatelessWidget {
  const _EditTaskSheetBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditTaskViewModel>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        // Avoid overflow when keyboard + image
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),
            Text('Edit Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // TITLE FIELD
            TextField(
              controller: vm.titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // DESCRIPTION FIELD
            TextField(
              controller: vm.descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // CATEGORY PICKER
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
                        color:
                            vm.selectedCategory == category ? category.color : null,
                        fontWeight: vm.selectedCategory == category
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 16),

            // TAGS SECTION
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: vm.tagCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Add a tag',
                      hintText: 'Ex: urgent, important',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    onSubmitted: vm.addTag,
                  ),
                ),
                const SizedBox(width: 8),

                IconButton(
                  onPressed: () => vm.addTag(vm.tagCtrl.text),
                  icon: const Icon(Icons.add_circle),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
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
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 16),

            // IMAGE SECTION
            Text('Photo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            if (!vm.hasImage)
              OutlinedButton.icon(
                onPressed: vm.pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add a photo'),
              )
            else ...[
              // NEW IMAGE (memory)
              if (vm.newImageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    vm.newImageBytes!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
              // EXISTING IMAGE (from network)
              else if (vm.currentImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    vm.currentImageUrl!,
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
                    onPressed: vm.removeImage,
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

            const SizedBox(height: 20),

            // ACTION BUTTONS (Cancel / Save)
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
                      final ok = await vm.update(context.read<TaskService>());
                      if (!ok) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a title'),
                          ),
                        );
                        return;
                      }

                      if (!context.mounted) return;

                      Navigator.pop(context);

                      // Confirmation message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Task "${vm.titleCtrl.text.trim()}" updated',
                          ),
                          backgroundColor: vm.selectedCategory.color,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
