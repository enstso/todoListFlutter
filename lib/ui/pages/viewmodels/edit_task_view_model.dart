import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

class EditTaskViewModel extends ChangeNotifier {
  final TaskModel original;

  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  final tagCtrl = TextEditingController();

  late TaskCategory _selectedCategory;
  late List<String> _tags;

  String? _currentImageUrl;
  Uint8List? _newImageBytes;
  bool _removeImage = false;

  EditTaskViewModel(this.original) {
    titleCtrl = TextEditingController(text: original.title);
    descCtrl = TextEditingController(text: original.description);
    _selectedCategory = original.category;
    _tags = List<String>.from(original.tags);
    _currentImageUrl = original.imageUrl;
  }

  TaskCategory get selectedCategory => _selectedCategory;
  List<String> get tags => List.unmodifiable(_tags);
  String? get currentImageUrl => _currentImageUrl;
  Uint8List? get newImageBytes => _newImageBytes;
  bool get hasImage =>
      (_currentImageUrl != null && !_removeImage) || _newImageBytes != null;

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

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null) return;

    _newImageBytes = await file.readAsBytes();
    _removeImage = false;
    notifyListeners();
  }

  void removeImage() {
    _newImageBytes = null;
    _removeImage = true;
    notifyListeners();
  }

  Future<bool> update(TaskService service) async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return false;

    final imageUrlToKeep = _removeImage ? null : _currentImageUrl;

    final updatedTask = TaskModel(
      id: original.id,
      userId: original.userId,
      title: title,
      description: descCtrl.text.trim(),
      isCompleted: original.isCompleted,
      createdAt: original.createdAt,
      completedAt: original.completedAt,
      category: _selectedCategory,
      tags: _tags,
      imageUrl: imageUrlToKeep,
    );

    await service.updateTask(
      updatedTask,
      imageBytes: _newImageBytes,
      removeImage: _removeImage, 
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
