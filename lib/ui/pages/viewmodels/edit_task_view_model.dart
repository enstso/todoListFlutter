import 'package:flutter/material.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

class EditTaskViewModel extends ChangeNotifier {
  final TaskModel original;

  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  final tagCtrl = TextEditingController();

  late TaskCategory _selectedCategory;
  late List<String> _tags;

  EditTaskViewModel(this.original) {
    titleCtrl = TextEditingController(text: original.title);
    descCtrl = TextEditingController(text: original.description);
    _selectedCategory = original.category;
    _tags = List<String>.from(original.tags);
  }

  TaskCategory get selectedCategory => _selectedCategory;
  List<String> get tags => List.unmodifiable(_tags);

  void setCategory(TaskCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }

  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;
    _tags.add(trimmed);
    tagCtrl.clear();
    notifyListeners();
  }

  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  Future<bool> update(TaskService service) async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return false;

    await service.updateTask(
      TaskModel(
        id: original.id,
        userId: original.userId,
        title: title,
        description: descCtrl.text.trim(),
        isCompleted: original.isCompleted,
        createdAt: original.createdAt,
        completedAt: original.completedAt,
        category: _selectedCategory,
        tags: _tags,
      ),
    );
    return true;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }
}
