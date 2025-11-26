import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/user/user_service.dart';
import 'package:todo_list/ui/pages/viewmodels/edit_task_view_model.dart';

///sheet used to edit an existing task.
/// It provides an [EditTaskViewModel] to the widget tree.
class EditTaskSheet extends StatelessWidget {
  final TaskModel task;

  const EditTaskSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // ViewModel keeps the editing state (title, desc, tags, assignee, image…)
      create: (_) => EditTaskViewModel(task),
      child: const _EditTaskSheetBody(),
    );
  }
}

/// Internal widget that renders the actual content of the edit sheet.
class _EditTaskSheetBody extends StatelessWidget {
  const _EditTaskSheetBody();

  @override
  Widget build(BuildContext context) {
    // Listen to ViewModel state changes
    final vm = context.watch<EditTaskViewModel>();
    final theme = Theme.of(context);
    final currentUserEmail = context.read<AuthService>().currentUser?.email;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        // Add bottom padding to avoid keyboard overlap
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        // Make sure content is scrollable when keyboard + image are visible
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            const SizedBox(height: 8),

            // Sheet title
            Text('Edit Task', style: theme.textTheme.titleLarge),
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
                          // Small colored dot that matches category color
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

            // ASSIGNED TO FIELD + VALIDATION UI
            Text('Assigned to', style: theme.textTheme.titleSmall),
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

            // Validation / error messages for assignee
            if (vm.assigneeError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  vm.assigneeError!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              )
            else if (vm.validatedAssigneeUid != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'User found for this email ✅',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // TAGS SECTION
            Text('Tags', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),

            Row(
              children: [
                // Tag input
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

            // Existing tag chips
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

            const SizedBox(height: 16),

            // IMAGE SECTION
            Text('Photo', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),

            // If there is no image at all (neither existing nor new)
            if (!vm.hasImage)
              OutlinedButton.icon(
                onPressed: vm.pickImage,
                icon: const Icon(Icons.photo),
                label: const Text('Add a photo'),
              )
            else ...[
              // IMAGE (selected from gallery in this session)
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
              // EXISTING IMAGE (stored URL from Firestore)
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

              // Actions for removing or changing the photo
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
                // Cancel → just close the sheet
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),

                const SizedBox(width: 12),

                // Save → validate + call ViewModel.update(...)
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final taskService = context.read<TaskService>();
                      final userService = context.read<UserService>();
                      final auth = context.read<AuthService>();
                      final currentUserEmail = auth.currentUser?.email;
                      final title = vm.titleCtrl.text.trim();

                      // Basic validation: title is required
                      if (title.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }

                      final assigneeText = vm.assignedToCtrl.text.trim();

                      // If an email is entered but not validated (and no error yet),
                      // we try one last validation automatically before saving.
                      if (assigneeText.isNotEmpty &&
                          vm.validatedAssigneeUid == null &&
                          vm.assigneeError == null) {
                        await vm.checkAssigneeEmail(
                          userService,
                          currentUserEmail: currentUserEmail,
                        );
                      }

                      // If there is still an error about assignee, stop and show it.
                      if (assigneeText.isNotEmpty && vm.assigneeError != null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(vm.assigneeError!)),
                        );
                        return;
                      }

                      // Call ViewModel update, which handles:
                      //  - image logic
                      //  - assignedTo + assignedToUid mapping
                      final ok = await vm.update(taskService);
                      if (!ok) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a title')),
                        );
                        return;
                      }

                      if (!context.mounted) return;

                      Navigator.pop(context);

                      // Confirmation SnackBar
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

/// Small visual handle at the top of the bottom sheet.
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
