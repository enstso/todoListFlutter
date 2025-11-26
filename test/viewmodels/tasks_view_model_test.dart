import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/enum/task_enum.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/pages/viewmodels/task_view_model.dart';

void main() {
  group('TasksViewModel', () {
    test('initial state is correct', () {
      // Arrange: create a fresh instance of the ViewModel
      final vm = TasksViewModel();

      // Assert: default filters and sort are correctly set
      expect(vm.selectedCategory, isNull);
      expect(vm.filterStatus, TaskFilterStatus.all);
      expect(vm.sortOrder, TaskSortOrder.newestFirst);
      expect(vm.searchQuery, '');
    });

    test('statusLabel returns correct labels', () {
      // Arrange
      final vm = TasksViewModel();

      // Act & Assert: each status enum should map to the expected label
      expect(vm.statusLabel(TaskFilterStatus.all), 'All');
      expect(vm.statusLabel(TaskFilterStatus.completed), 'Completed');
      expect(vm.statusLabel(TaskFilterStatus.pending), 'Pending');
    });

    test('sortLabel returns correct labels', () {
      // Arrange
      final vm = TasksViewModel();

      // Act & Assert: each sort enum should map to the expected label
      expect(vm.sortLabel(TaskSortOrder.newestFirst), 'Most recent');
      expect(vm.sortLabel(TaskSortOrder.oldestFirst), 'Older');
      expect(vm.sortLabel(TaskSortOrder.alphabetical), 'A-Z');
    });

    test('applyFiltersAndSort filters by search, category and status', () {
      final vm = TasksViewModel();

      // Create two tasks with different titles, categories and completion states
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

      // 1) No filters => both tasks should be visible
      var visible = vm.applyFiltersAndSort(tasks);
      expect(visible.length, 2);

      // 2) Search filter: search "milk" should only match the first task
      vm.setSearchQuery('milk');
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t1]);

      // 3) Reset search and filter by category "work"
      vm.setSearchQuery('');
      vm.setCategory(TaskCategory.work);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t2]);

      // 4) Filter by completed status (regardless of category)
      vm.setCategory(null);
      vm.setFilterStatus(TaskFilterStatus.completed);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t2]);

      // 5) Filter by pending status
      vm.setFilterStatus(TaskFilterStatus.pending);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible, [t1]);
    });

    test('applyFiltersAndSort sorts according to sortOrder', () {
      final vm = TasksViewModel();

      // Two tasks with different dates and titles
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

      // 1) Default sort: newestFirst => the newer task should come first
      var visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first, newer);

      // 2) Sort by oldestFirst => the older task should come first
      vm.setSortOrder(TaskSortOrder.oldestFirst);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first, older);

      // 3) Sort alphabetically by title => "A task" should come first
      vm.setSortOrder(TaskSortOrder.alphabetical);
      visible = vm.applyFiltersAndSort(tasks);
      expect(visible.first.title, 'A task');
    });
  });
}