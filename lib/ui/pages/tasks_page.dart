import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/pages/viewmodels/task_view_model.dart';
import '../widgets/task_tile.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/category_filter.dart';
import 'sign_in_page.dart';
import 'package:todo_list/enum/task_enum.dart';

class TasksPage extends StatelessWidget {
  static const route = '/tasks';
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access TaskService from Provider (used for fetching tasks)
    final taskService = context.read<TaskService>();

    return MultiProvider(
      providers: [
        // ViewModel that handles filters, sorting, search
        ChangeNotifierProvider(create: (_) => TasksViewModel()),

        // Live stream of tasks from Firestore for the logged user
        StreamProvider<List<TaskModel>>.value(
          value: taskService.getTasks(),
          initialData: const [],
        ),
      ],
      child: const _TasksScaffold(),
    );
  }
}

class _TasksScaffold extends StatelessWidget {
  const _TasksScaffold();

  @override
  Widget build(BuildContext context) {
    // ViewModel for filters and sorting
    final vm = context.watch<TasksViewModel>();

    return Scaffold(
      appBar: AppBar(
        // Display the app logo instead of a text title
        title: Image.asset(
          'assets/logo.png',
          height: 75,
        ),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),

          // Filters button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),

          // Logout icon -> redirect to sign-in page
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(SignInPage.route);
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // Horizontal category filter (UI chips)
          CategoryFilter(
            selectedCategory: vm.selectedCategory,
            onCategorySelected: vm.setCategory,
          ),

          // Display active filters at the top
          const _ActiveFilters(),

          // List of tasks (filtered + sorted)
          const Expanded(child: _TaskList()),
        ],
      ),

      // FAB to add a new task
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => const AddTaskSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
    );
  }
}

// ---------------------------
// SEARCH POPUP
// ---------------------------
void _showSearchDialog(BuildContext context) {
  final vm = context.read<TasksViewModel>();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Search'),
      content: TextField(
        autofocus: true,
        onChanged: vm.setSearchQuery,
        decoration: const InputDecoration(
          hintText: 'Search by title, description or tags...',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            vm.clearSearch();
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

// ---------------------------
// FILTER POPUP
// ---------------------------
void _showFilterDialog(BuildContext context) {
  // Reuse existing TasksViewModel instance
  final vm = context.read<TasksViewModel>();

  showDialog(
    context: context,
    builder: (dialogCtx) => ChangeNotifierProvider.value(
      value: vm,
      child: Builder(
        builder: (innerCtx) {
          final watchVm = innerCtx.watch<TasksViewModel>();

          return AlertDialog(
            title: const Text('Filter and sort'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status filter
                Text('Status', style: Theme.of(innerCtx).textTheme.titleSmall),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: TaskFilterStatus.values.map((status) {
                    return FilterChip(
                      label: Text(watchVm.statusLabel(status)),
                      selected: watchVm.filterStatus == status,
                      onSelected: (_) => watchVm.setFilterStatus(status),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Sort filter
                Text('Sort by', style: Theme.of(innerCtx).textTheme.titleSmall),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  children: TaskSortOrder.values.map((order) {
                    return FilterChip(
                      label: Text(watchVm.sortLabel(order)),
                      selected: watchVm.sortOrder == order,
                      onSelected: (_) => watchVm.setSortOrder(order),
                    );
                  }).toList(),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  watchVm.resetFilters();
                  Navigator.pop(innerCtx);
                },
                child: const Text('Remove All filters'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(innerCtx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    ),
  );
}

// ---------------------------
// ACTIVE FILTERS BANNER
// ---------------------------
class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();

    // Determine if something is filtered
    final hasActiveFilters =
        vm.selectedCategory != null ||
        vm.filterStatus != TaskFilterStatus.all ||
        vm.searchQuery.isNotEmpty;

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          // Category filter chip
          if (vm.selectedCategory != null)
            _FilterChip(
              label: vm.selectedCategory!.displayName,
              color: vm.selectedCategory!.color,
              onDeleted: vm.clearCategory,
            ),

          // Status filter chip
          if (vm.filterStatus != TaskFilterStatus.all)
            _FilterChip(
              label: vm.statusLabel(vm.filterStatus),
              onDeleted: () => vm.setFilterStatus(TaskFilterStatus.all),
            ),

          // Search filter chip
          if (vm.searchQuery.isNotEmpty)
            _FilterChip(
              label: 'Search: ${vm.searchQuery}',
              onDeleted: vm.clearSearch,
            ),
        ],
      ),
    );
  }
}

// ---------------------------
// TASK LIST (FILTERED + SORTED)
// ---------------------------
class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TasksViewModel>();

    // Tasks retrieved from StreamProvider
    final tasks = context.watch<List<TaskModel>>();

    // Apply filters + sorting
    final visible = vm.applyFiltersAndSort(tasks);

    // Empty state UI
    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No task found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks match your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: vm.resetFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    // List of visible tasks
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => TaskTile(task: visible[i]),
    );
  }
}

// ---------------------------
// UI CHIP USED FOR ACTIVE FILTERS
// ---------------------------
class _FilterChip extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onDeleted;

  const _FilterChip({required this.label, this.color, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: color?.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
