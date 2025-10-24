import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:intl/intl.dart';
import 'package:todo_list/services/notifications/notification_service.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: InkWell(
          onTap: () => _toggle(context),
          child: CircleAvatar(
            child: Icon(task.isCompleted ? Icons.check : Icons.circle_outlined),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
  children: [
    if (task.description.isNotEmpty)
      Text(
        task.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    const SizedBox(height: 6),
    // Show creation date
    Row(
      children: [
        const Icon(Icons.schedule, size: 14),
        const SizedBox(width: 6),
        Text(
          'Created: ${DateFormat.yMMMEd().add_Hm().format(task.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
    // Show reminder if available
    if (task.reminderAt != null) ...[
      const SizedBox(height: 2),
      Row(
        children: [
          const Icon(Icons.notifications_active, size: 14),
          const SizedBox(width: 6),
          Text(
            'Rappel: ${DateFormat.yMMMEd().add_Hm().format(task.reminderAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ],
    // Show completion date if available
    if (task.completedAt != null) ...[
      const SizedBox(height: 2),
      Row(
        children: [
          const Icon(Icons.check_circle, size: 14),
          const SizedBox(width: 6),
          Text(
            'Completed: ${DateFormat.yMMMEd().add_Hm().format(task.completedAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
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
            PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
            PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Supprimer'))),
          ],
        ),
        tileColor: task.isCompleted ? theme.surfaceVariant.withOpacity(.6) : null,
      ),
    );
  }

  void _toggle(BuildContext context) {
    final service = context.read<TaskService>();
    final updated = TaskModel(
      id: task.id,
      userId: task.userId,
      title: task.title,
      description: task.description,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
      completedAt: !task.isCompleted ? DateTime.now() : null,
      reminderAt: task.reminderAt,
    );
    service.updateTask(updated);
    // If completed, cancel reminder
    if (!task.isCompleted && task.reminderAt != null) {
      final notif = context.read<NotificationService>();
      notif.cancelReminder(task.id);
    } else if (task.isCompleted && task.reminderAt != null && task.reminderAt!.isAfter(DateTime.now())) {
      // If re-opened and reminder is in the future, reschedule
      final notif = context.read<NotificationService>();
      notif.scheduleReminder(
        taskId: task.id,
        when: task.reminderAt!,
        title: 'Rappel: ${task.title}',
        body: task.description.isEmpty ? 'Vous avez un rappel' : task.description,
      );
    }
  }

  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
    if (task.reminderAt != null) {
      final notif = context.read<NotificationService>();
      await notif.cancelReminder(task.id);
    }
    await service.deleteTask(task.id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tâche supprimée')));
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditTaskSheet(task: task),
    );
  }
}

class _EditTaskSheet extends StatelessWidget {
  final TaskModel task;
  const _EditTaskSheet({required this.task});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    DateTime? reminderAt = task.reminderAt;

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
          Text('Modifier la tâche', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Titre'), controller: titleCtrl),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Description'),
            controller: descCtrl,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: context,
                        initialDate: reminderAt ?? now.add(const Duration(minutes: 10)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: reminderAt != null
                            ? TimeOfDay.fromDateTime(reminderAt!)
                            : TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
                      );
                      if (time == null) return;
                      final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      setState(() => reminderAt = selected);
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: Text(reminderAt == null
                        ? 'Ajouter un rappel'
                        : 'Rappel: ${DateFormat.yMMMEd().add_Hm().format(reminderAt!)}'),
                  ),
                  if (reminderAt != null)
                    TextButton.icon(
                      onPressed: () => setState(() => reminderAt = null),
                      icon: const Icon(Icons.close),
                      label: const Text('Supprimer le rappel'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
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
                  onPressed: () async {
                    final service = context.read<TaskService>();
                    final updated = TaskModel(
                      id: task.id,
                      userId: task.userId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      isCompleted: task.isCompleted,
                      createdAt: task.createdAt,
                      completedAt: task.completedAt,
                      reminderAt: reminderAt,
                    );
                    await service.updateTask(updated);
                    final notif = context.read<NotificationService>();
                    if (reminderAt != null) {
                      await notif.scheduleReminder(
                        taskId: task.id,
                        when: reminderAt!,
                        title: 'Rappel: ${titleCtrl.text.trim()}',
                        body: descCtrl.text.trim().isEmpty ? 'Vous avez un rappel' : descCtrl.text.trim(),
                      );
                    } else {
                      await notif.cancelReminder(task.id);
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Enregistrer'),
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
