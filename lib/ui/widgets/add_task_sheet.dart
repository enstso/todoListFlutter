import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/user/user_service.dart'; // ⬅️ add this
import 'package:todo_list/ui/pages/viewmodels/add_task_view_model.dart';

// Bottom sheet widget used to create a new task.
// This widget provides an AddTaskViewModel to manage form state.
class AddTaskSheet extends StatelessWidget {
  const AddTaskSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject ViewModel into widget tree
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
    // ViewModel holds all form logic (title, tags, category, image, assignee …)
    final vm = context.watch<AddTaskViewModel>();
    final theme = Theme.of(context);
    final currentUserEmail = context.read<AuthService>().currentUser?.email;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + 16, // handle keyboard
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),

            // Title section
            Text('New task', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),

            // TITLE INPUT
            TextField(
              controller: vm.titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Ex: Buy milk',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // DESCRIPTION INPUT
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

            // ASSIGNED TO INPUT + VALIDATION
            Text('Assigned to', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: vm.assignedToCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Assignee (optional)',
                hintText: 'Ex: user@example.com',
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: vm.isCheckingAssignee
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        tooltip: 'Check email',
                        icon: const Icon(Icons.check),
                        onPressed: () => vm.checkAssigneeEmail(
                          context.read<UserService>(),
                          currentUserEmail: currentUserEmail,
                        ),
                      ),
              ),
              onChanged: (_) => vm.clearAssigneeValidation(),
              onSubmitted: (_) => vm.checkAssigneeEmail(
                context.read<UserService>(),
                currentUserEmail: currentUserEmail,
              ),
            ),

            // Assignee validation message
            if (vm.assigneeError != null) ...[
              const SizedBox(height: 4),
              Text(
                vm.assigneeError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ] else if (vm.validatedAssigneeUid != null) ...[
              const SizedBox(height: 4),
              Text(
                'User found and valid',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // CATEGORY SELECTION
            Text('Category', style: theme.textTheme.titleSmall),
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
                          // Small color dot matching category color
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

            // TAGS SECTION
            Text('Tags', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),

            Row(
              children: [
                // Tag text field
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

                // Add tag button
                IconButton(
                  onPressed: () => vm.addTag(vm.tagCtrl.text),
                  icon: const Icon(Icons.add_circle),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),

            // Display added tags
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
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
            ],

            const SizedBox(height: 20),

            // PHOTO SECTION
            Text('Photo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),

            // If no image selected
            if (vm.imageBytes == null)
              OutlinedButton.icon(
                onPressed: vm.pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add a photo'),
              )
            else
              // Image preview
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

                  // Buttons to remove or change photo
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

            // ACTION BUTTONS
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
                      final taskService = context.read<TaskService>();
                      final userService = context.read<UserService>();
                      final auth = context.read<AuthService>();
                      final currentUserEmail = auth.currentUser?.email;

                      final title = vm.titleCtrl.text.trim();

                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }

                      final assigneeText = vm.assignedToCtrl.text.trim();

                      if (assigneeText.isNotEmpty &&
                          vm.validatedAssigneeUid == null &&
                          vm.assigneeError == null) {
                        await vm.checkAssigneeEmail(
                          userService,
                          currentUserEmail: currentUserEmail,
                        );
                      }

                      if (!context.mounted) return;

                      if (assigneeText.isNotEmpty && vm.assigneeError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(vm.assigneeError!)),
                        );
                        return;
                      }

                      String? assignedToEmail = assigneeText.isEmpty
                          ? null
                          : assigneeText;

                      String? assignedToUid;
                      if (assignedToEmail != null) {
                        assignedToUid = vm.validatedAssigneeUid;
                        if (assignedToUid == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please validate the assignee email first',
                              ),
                            ),
                          );
                          return;
                        }
                      }

                      final newTask = TaskModel(
                        id: '_',
                        userId: '_',
                        title: title,
                        description: vm.descCtrl.text.trim(),
                        isCompleted: false,
                        createdAt: DateTime.now(),
                        category: vm.selectedCategory,
                        tags: vm.tags,
                        imageUrl: null,
                        assignedTo: assignedToEmail,
                        assignedToUid: assignedToUid,
                      );

                      await taskService.addTask(
                        newTask,
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
      ),
    );
  }
}

// Small handle displayed at the top of the bottom sheet
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
