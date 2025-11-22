import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/ui/pages/viewmodels/edit_task_view_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: task.category.color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: task.category.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _toggle(context),
                child: CircleAvatar(
                  backgroundColor: task.isCompleted
                      ? task.category.color.withValues(alpha: 0.2)
                      : null,
                  child: Icon(
                    task.isCompleted ? Icons.check : Icons.circle_outlined,
                    color: task.isCompleted ? task.category.color : null,
                  ),
                ),
              ),
            ],
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
              color: task.isCompleted ? theme.onSurfaceVariant : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Catégorie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: task.category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  task.category.displayName,
                  style: TextStyle(
                    color: task.category.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Description
              if (task.description.isNotEmpty)
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: task.isCompleted ? theme.onSurfaceVariant : null,
                  ),
                ),
              if (task.description.isNotEmpty) const SizedBox(height: 6),

              // Image (optionnelle)
              if (task.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    task.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Tags (if any)
              if (task.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  children: task.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 6),
              ],

              // Creation date
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: theme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Created: ${DateFormat.yMMMEd().add_Hm().format(task.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              task.isCompleted ? theme.onSurfaceVariant : null,
                        ),
                  ),
                ],
              ),

              // Completion date if available
              if (task.completedAt != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: task.category.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Completed: ${DateFormat.yMMMEd().add_Hm().format(task.completedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: task.category.color,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _edit(context);
              if (v == 'delete') _delete(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
            ],
          ),
          tileColor: task.isCompleted
              ? task.category.color.withValues(alpha: 0.05)
              : theme.surface,
        ),
      ),
    );
  }

  void _toggle(BuildContext context) {
    final service = context.read<TaskService>();
    service.updateTask(
      TaskModel(
        id: task.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        isCompleted: !task.isCompleted,
        category: task.category,
        createdAt: task.createdAt,
        completedAt: !task.isCompleted ? DateTime.now() : null,
        tags: task.tags,
        imageUrl: task.imageUrl, // on conserve l'image existante
      ),
    );
  }

  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
    await service.deleteTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider(
        create: (_) => EditTaskViewModel(task),
        child: const _EditTaskSheetBody(),
      ),
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
        // pour éviter overflow si image + clavier
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),
            Text('Edit Task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Title
            TextField(
              controller: vm.titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: vm.descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category
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

            // Tags
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

            // Photo
            Text('Photo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),

            if (!vm.hasImage)
              OutlinedButton.icon(
                onPressed: vm.pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add a photo'),
              )
            else ...[
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

            // Buttons
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
                      final ok =
                          await vm.update(context.read<TaskService>());
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
