import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/auth/auth_service.dart';
import 'package:todo_list/services/task/task_service.dart';
import '../widgets/task_tile.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/category_filter.dart';
import 'sign_in_page.dart';
import 'package:todo_list/enum/task_enum.dart';

class TasksPage extends StatefulWidget {
  static const route = '/tasks';
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  TaskCategory? selectedCategory;
  TaskFilterStatus filterStatus = TaskFilterStatus.all;
  TaskSortOrder sortOrder = TaskSortOrder.newestFirst;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final taskService = context.read<TaskService>();

    Stream<List<TaskModel>> taskStream = _getFilteredTasks(taskService);

    return StreamProvider<List<TaskModel>>.value(
      value: taskStream,
      initialData: const [],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes tâches'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _showSearchDialog(context),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
            IconButton(
              tooltip: 'Se déconnecter',
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
            // Category Filter
            CategoryFilter(
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                setState(() => selectedCategory = category);
              },
            ),
            // Active Filters Display
            _buildActiveFilters(),
            // Task List
            const Expanded(child: _TaskList()),
          ],
        ),
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
          label: const Text('Nouvelle tâche'),
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final hasActiveFilters =
        selectedCategory != null ||
        filterStatus != TaskFilterStatus.all ||
        searchQuery.isNotEmpty;

    if (!hasActiveFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          if (selectedCategory != null)
            _FilterChip(
              label: selectedCategory!.displayName,
              color: selectedCategory!.color,
              onDeleted: () => setState(() => selectedCategory = null),
            ),
          if (filterStatus != TaskFilterStatus.all)
            _FilterChip(
              label: _getStatusLabel(filterStatus),
              onDeleted: () =>
                  setState(() => filterStatus = TaskFilterStatus.all),
            ),
          if (searchQuery.isNotEmpty)
            _FilterChip(
              label: 'Search: $searchQuery',
              onDeleted: () => setState(() => searchQuery = ''),
            ),
        ],
      ),
    );
  }

  String _getStatusLabel(TaskFilterStatus status) {
    switch (status) {
      case TaskFilterStatus.completed:
        return 'Completed';
      case TaskFilterStatus.pending:
        return 'Pending';
      case TaskFilterStatus.all:
        return 'All';
    }
  }

  Stream<List<TaskModel>> _getFilteredTasks(TaskService taskService) {
    Stream<List<TaskModel>> baseStream;

    if (searchQuery.isNotEmpty) {
      baseStream = taskService.searchTasks(searchQuery);
    } else if (selectedCategory != null) {
      baseStream = taskService.getTasksByCategory(selectedCategory!);
      if(baseStream.isEmpty == true){
        print('baseStream is empty');
      }else{
        print('baseStream is not empty');
      }
    } else {
      baseStream = taskService.getTasks();
    }


    baseStream.listen((tasks) {
      tasks.forEach((task) {
        print('task: ${task.title}');
      });
    });

    return baseStream.map((tasks) {
      // Apply status filter
      List<TaskModel> filteredTasks = tasks.where((task) {
        switch (filterStatus) {
          case TaskFilterStatus.completed:
            return task.isCompleted;
          case TaskFilterStatus.pending:
            return !task.isCompleted;
          case TaskFilterStatus.all:
            return true;
        }
      }).toList();

      // Apply sorting
      filteredTasks.sort((a, b) {
        switch (sortOrder) {
          case TaskSortOrder.newestFirst:
            return b.createdAt.compareTo(a.createdAt);
          case TaskSortOrder.oldestFirst:
            return a.createdAt.compareTo(b.createdAt);
          case TaskSortOrder.alphabetical:
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
      });

      return filteredTasks;
    });
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          autofocus: true,
          onChanged: (value) => setState(() => searchQuery = value),
          decoration: const InputDecoration(
            hintText: 'Rechercher par titre, description ou tags...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => searchQuery = '');
              Navigator.pop(context);
            },
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filtres et tri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status Filter
              Text('Statut', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskFilterStatus.values
                    .map(
                      (status) => FilterChip(
                        label: Text(_getStatusLabel(status)),
                        selected: filterStatus == status,
                        onSelected: (_) =>
                            setDialogState(() => filterStatus = status),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Sort Order
              Text('Trier par', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskSortOrder.values
                    .map(
                      (order) => FilterChip(
                        label: Text(_getSortLabel(order)),
                        selected: sortOrder == order,
                        onSelected: (_) =>
                            setDialogState(() => sortOrder = order),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  filterStatus = TaskFilterStatus.all;
                  sortOrder = TaskSortOrder.newestFirst;
                });
                Navigator.pop(context);
              },
              child: const Text('Réinitialiser'),
            ),
            TextButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      selectedCategory = null;
      filterStatus = TaskFilterStatus.all;
      searchQuery = '';
    });
  }

  String _getSortLabel(TaskSortOrder order) {
    switch (order) {
      case TaskSortOrder.newestFirst:
        return 'Plus récent';
      case TaskSortOrder.oldestFirst:
        return 'Plus ancien';
      case TaskSortOrder.alphabetical:
        return 'A-Z';
    }
  }
}

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
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList();

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<List<TaskModel>>();

    if (tasks.isEmpty) {
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
              'Aucune tâche trouvée',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune tâche ne correspond à vos filtres',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Réinitialiser tous les filtres
                final state = context
                    .findAncestorStateOfType<_TasksPageState>();
                if (state != null) {
                  state._clearAllFilters();
                }
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer les filtres'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => TaskTile(task: tasks[i]),
    );
  }
}
