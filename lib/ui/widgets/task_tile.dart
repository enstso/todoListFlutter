import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/ui/widgets/edit_task_sheet.dart';

// A single visual tile representing one task in the list.
// Supports: display, toggle complete, edit, delete, image preview, tags, category color, etc.
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
        // Outer colored border matching category
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

          // Left side: colored bar + toggle check button
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored vertical bar (category color)
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: task.category.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),

              // Tap to toggle completed state
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

          // Task title
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
              color: task.isCompleted ? theme.onSurfaceVariant : null,
            ),
          ),

          // Subtitle with category, description, image, tags, dates
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // CATEGORY BADGE
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

              // DESCRIPTION (optional)
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

              // IMAGE (optional)
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

              // TAGS (up to 3 are shown)
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

              // CREATION DATE
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

              // COMPLETION DATE (if completed)
              if (task.completedAt != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: task.category.color),
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

          // Popup menu: Edit / Delete
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

          // Background color if completed
          tileColor: task.isCompleted
              ? task.category.color.withValues(alpha: 0.05)
              : theme.surface,
        ),
      ),
    );
  }

  // Toggle the isCompleted state of the task
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
        imageUrl: task.imageUrl, // keep existing image
      ),
    );
  }

  // Delete the task
  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
    await service.deleteTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  // Open bottom sheet to edit the task (now uses the extracted widget)
  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTaskSheet(task: task),
    );
  }
}
