import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:intl/intl.dart';

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
              // Completion checkbox
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
              // Category chip
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
                            color: theme.surfaceVariant,
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
                      color: task.isCompleted ? theme.onSurfaceVariant : null,
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
                  title: Text('Modifier'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Supprimer'),
                ),
              ),
            ],
          ),
          tileColor: task.isCompleted
              ? task.category.color.withOpacity(0.05)
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
      ),
    );
  }

  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
    await service.deleteTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditTaskSheet(task: task),
    );
  }
}

class _EditTaskSheet extends StatefulWidget {
  final TaskModel task;
  const _EditTaskSheet({required this.task});

  @override
  State<_EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<_EditTaskSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  late final TextEditingController tagCtrl;

  late TaskCategory selectedCategory;
  late List<String> tags;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.task.title);
    descCtrl = TextEditingController(text: widget.task.description);
    tagCtrl = TextEditingController();
    selectedCategory = widget.task.category;
    tags = List<String>.from(widget.task.tags);
  }

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
          Text(
            'Edit Task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Title Field
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          // Description Field
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
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

          Text('Tags', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: tagCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Add a tag',
                    hintText: 'Ex: urgent, important',
                    prefixIcon: Icon(Icons.tag),
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
                      ).colorScheme.surfaceContainerHighest,
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
                  onPressed: _updateTask,
                  child: const Text('Enregistrer'),
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

  void _updateTask() async {
    if (titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    final service = context.read<TaskService>();
    await service.updateTask(
      TaskModel(
        id: widget.task.id,
        userId: widget.task.userId,
        title: titleCtrl.text.trim(),
        description: descCtrl.text.trim(),
        isCompleted: widget.task.isCompleted,
        createdAt: widget.task.createdAt,
        completedAt: widget.task.completedAt,
        category: selectedCategory, // NEW
        tags: tags, // NEW
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task "${titleCtrl.text.trim()}" updated'),
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
