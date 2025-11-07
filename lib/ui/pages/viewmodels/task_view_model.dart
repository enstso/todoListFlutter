import 'package:flutter/foundation.dart';
import 'package:todo_list/enum/task_enum.dart';
import 'package:todo_list/models/task_model.dart';

class TasksViewModel extends ChangeNotifier {
  TaskCategory? _selectedCategory;
  TaskFilterStatus _filterStatus = TaskFilterStatus.all;
  TaskSortOrder _sortOrder = TaskSortOrder.newestFirst;
  String _searchQuery = '';

  TaskCategory? get selectedCategory => _selectedCategory;
  TaskFilterStatus get filterStatus => _filterStatus;
  TaskSortOrder get sortOrder => _sortOrder;
  String get searchQuery => _searchQuery;

  void setCategory(TaskCategory? c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void clearCategory() => setCategory(null);

  void setFilterStatus(TaskFilterStatus s) {
    _filterStatus = s;
    notifyListeners();
  }

  void setSortOrder(TaskSortOrder o) {
    _sortOrder = o;
    notifyListeners();
  }

  void setSearchQuery(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void clearSearch() => setSearchQuery('');

  void resetFilters() {
    _selectedCategory = null;
    _filterStatus = TaskFilterStatus.all;
    _sortOrder = TaskSortOrder.newestFirst;
    _searchQuery = '';
    notifyListeners();
  }

  // Labels
  String statusLabel(TaskFilterStatus status) {
    switch (status) {
      case TaskFilterStatus.completed:
        print(status);
        return 'Completed';
      case TaskFilterStatus.pending:
        print(status);
        return 'Pending';
      case TaskFilterStatus.all:
        print(status);
        return 'All';
    }
  }

  String sortLabel(TaskSortOrder order) {
    switch (order) {
      case TaskSortOrder.newestFirst:
        print(order);
        return 'Most recent';
      case TaskSortOrder.oldestFirst:
        print(order);
        return 'Older';
      case TaskSortOrder.alphabetical:
        print(order);
        return 'A-Z';
    }
  }

  List<TaskModel> applyFiltersAndSort(List<TaskModel> tasks) {
    Iterable<TaskModel> res = tasks;

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      res = res.where(
        (t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q)),
      );
    }

    if (_selectedCategory != null) {
      res = res.where((t) => t.category == _selectedCategory);
    }

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

    final list = res.toList();
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
