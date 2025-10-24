import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/notifications/notification_service.dart';
import 'package:intl/intl.dart';

class AddTaskSheet extends StatelessWidget {
  const AddTaskSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? reminderAt;

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
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Titre',
              hintText: 'Ex: Acheter du lait',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Détails (optionnel)',
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
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
                        initialDate: now.add(const Duration(minutes: 10)),
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(minutes: 10))),
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
                    final task = TaskModel(
                      id: '_',
                      userId: '_',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      isCompleted: false,
                      createdAt: DateTime.now(),
                      reminderAt: reminderAt,
                    );
                    final newId = await service.addTask(task);
                    if (reminderAt != null) {
                      final notif = context.read<NotificationService>();
                      await notif.scheduleReminder(
                        taskId: newId,
                        when: reminderAt!,
                        title: 'Rappel: ${titleCtrl.text.trim()}',
                        body: descCtrl.text.trim().isEmpty ? 'Vous avez un rappel' : descCtrl.text.trim(),
                      );
                    }
                    if (context.mounted) Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tâche ajoutée')),
                    );
                  },
                  child: const Text('Ajouter'),
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
