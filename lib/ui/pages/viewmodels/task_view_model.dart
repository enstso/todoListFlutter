import 'package:flutter/foundation.dart';
import 'package:todo_list/enum/task_enum.dart';
import 'package:todo_list/models/task_model.dart';

// ViewModel responsible for managing task filters, sorting, and search query.
// It does not fetch tasks; instead, it receives them and processes them
// (filters + sorting) in applyFiltersAndSort().
class TasksViewModel extends ChangeNotifier {
  // Currently selected category filter (nullable = no category filter)
  TaskCategory? _selectedCategory;

  // Current status filter (all / completed / pending)
  TaskFilterStatus _filterStatus = TaskFilterStatus.all;

  // Current sorting preference (newest, oldest, alphabetical)
  TaskSortOrder _sortOrder = TaskSortOrder.newestFirst;

  // Current text search query
  String _searchQuery = '';

  // Public getters to expose filter state
  TaskCategory? get selectedCategory => _selectedCategory;
  TaskFilterStatus get filterStatus => _filterStatus;
  TaskSortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;

  // Updates selected category and notifies UI observers
  void setCategory(TaskCategory? c) {
    _selectedCategory = c;
    notifyListeners();
  }

  // Clears category filter quickly
  void clearCategory() => setCategory(null);

  // Updates status filter (all/pending/completed)
  void setFilterStatus(TaskFilterStatus s) {
    _filterStatus = s;
    notifyListeners();
  }

  // Updates sorting method
  void setSortOrder(TaskSortOrder o) {
    _sortOrder = o;
    notifyListeners();
  }

  // Updates the text search query
  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  // Clears search bar text
  void clearSearch() => setSearchQuery('');

  // Resets all filters and sorting to default values
  void resetFilters() {
    _selectedCategory = null;
    _filterStatus = TaskFilterStatus.all;
    _sortOrder = TaskSortOrder.newestFirst;
    _searchQuery = '';
    notifyListeners();
  }

  // Provides a human-readable label for status filters
  String statusLabel(TaskFilterStatus status) {
    switch (status) {
      case TaskFilterStatus.completed:
        return 'Completed';
      case TaskFilterStatus.pending:
        return 'Pending';
      case TaskFilterStatus.all:
        return 'All';
    }
  }

  // Provides a label for sorting order
  String sortLabel(TaskSortOrder order) {
    switch (order) {
      case TaskSortOrder.newestFirst:
        return 'Most recent';
      case TaskSortOrder.oldestFirst:
        return 'Older';
      case TaskSortOrder.alphabetical:
        return 'A-Z';
    }
  }

  // Main method that applies search, category filtering,
  // status filtering, and sorting on the list of tasks.
  List<TaskModel> applyFiltersAndSort(List<TaskModel> tasks) {
    // Start with all tasks
    Iterable<TaskModel> res = tasks;

    // Text-based search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      res = res.where(
        (t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q)),
      );
    }

    // Category filter
    if (_selectedCategory != null) {
      res = res.where((t) => t.category == _selectedCategory);
    }

    // Completed / Pending / All filter
    res = res.where((t) {
      switch (_filterStatus) {
        case TaskFilterStatus.completed:
          return t.isCompleted;
        case TaskFilterStatus.pending:
          return !t.isCompleted;
        case TaskFilterStatus.all:
          return true;
      }
    });

    // Convert iterable to list for sorting
    final list = res.toList();

    // Sorting based on user's chosen order
    list.sort((a, b) {
      switch (_sortOrder) {
        case TaskSortOrder.newestFirst:
          return b.createdAt.compareTo(a.createdAt);
        case TaskSortOrder.oldestFirst:
          return a.createdAt.compareTo(b.createdAt);
        case TaskSortOrder.alphabetical:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return list;
  }
}
