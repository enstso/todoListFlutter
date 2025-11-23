import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/enum/task_enum.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/pages/viewmodels/task_view_model.dart';

void main() {
  group('TasksViewModel', () {
    test('initial state is correct', () {
      // Arrange
      final vm = TasksViewModel();

      // Assert
      expect(vm.selectedCategory, isNull);
      expect(vm.filterStatus, TaskFilterStatus.all);
      expect(vm.sortOrder, TaskSortOrder.newestFirst);
      expect(vm.searchQuery, '');
    });

    test('statusLabel returns correct labels', () {
      final vm = TasksViewModel();

      // We just check that each enum value maps to the expected string.
      expect(vm.statusLabel(TaskFilterStatus.all), 'All');
      expect(vm.statusLabel(TaskFilterStatus.completed), 'Completed');
      expect(vm.statusLabel(TaskFilterStatus.pending), 'Pending');
    });

    test('sortLabel returns correct labels', () {
      final vm = TasksViewModel();

      expect(vm.sortLabel(TaskSortOrder.newestFirst), 'Most recent');
      expect(vm.sortLabel(TaskSortOrder.oldestFirst), 'Older');
      expect(vm.sortLabel(TaskSortOrder.alphabetical), 'A-Z');
    });

    test('applyFiltersAndSort filters by search, category and status', () {
      final vm = TasksViewModel();

      // Create two tasks with different properties
      final t1 = TaskModel(
        id: '1',
        userId: 'u1',
        title: 'Buy milk',
        description: 'From the supermarket',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 2),
        category: TaskCategory.shopping,
        tags: const ['urgent'],
      );

      final t2 = TaskModel(
        id: '2',
        userId: 'u1',
        title: 'Finish report',
        description: 'Due tomorrow',
        isCompleted: true,
        createdAt: DateTime(2024, 1, 1),
        category: TaskCategory.work,
        tags: const ['office'],
      );

      final tasks = [t1, t2];

      // No filters => both tasks are visible
      var visible = vm.applyFiltersAndSort(tasks);
      expect(visible.length, 2);

      // Search filter: only "milk"
      vm.setSearchQuery('milk');
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t1]);

      // Reset search and filter by category "work"
      vm.setSearchQuery('');
      vm.setCategory(TaskCategory.work);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t2]);

      // Filter by completed status
      vm.setCategory(null);
      vm.setFilterStatus(TaskFilterStatus.completed);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t2]);

      // Filter by pending status
      vm.setFilterStatus(TaskFilterStatus.pending);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t1]);
    });

    test('applyFiltersAndSort sorts according to sortOrder', () {
      final vm = TasksViewModel();

      final newer = TaskModel(
        id: '1',
        userId: 'u1',
        title: 'B task',
        description: '',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 2),
        category: TaskCategory.other,
        tags: const [],
      );

      final older = TaskModel(
        id: '2',
        userId: 'u1',
        title: 'A task',
        description: '',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        category: TaskCategory.other,
        tags: const [],
      );

      final tasks = [older, newer];

      // Default sort: newestFirst => newer comes first
      var visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first, newer);

      // Sort oldestFirst => older comes first
      vm.setSortOrder(TaskSortOrder.oldestFirst);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first, older);

      // Sort alphabetical => A task comes first
      vm.setSortOrder(TaskSortOrder.alphabetical);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first.title, 'A task');
    });
  });
}
