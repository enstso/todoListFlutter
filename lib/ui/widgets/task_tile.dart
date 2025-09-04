import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

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
        subtitle: Text(
          task.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
    service.updateTask(TaskModel(
      id: task.id,
      title: task.title,
      description: task.description,
      isCompleted: !task.isCompleted,
      createdAt: task.createdAt,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    ));
  }

  void _delete(BuildContext context) async {
    final service = context.read<TaskService>();
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
                    await service.updateTask(TaskModel(
                      id: task.id,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      isCompleted: task.isCompleted,
                      createdAt: task.createdAt,
                      completedAt: task.completedAt,
                    ));
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
