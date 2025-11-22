import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

// ViewModel responsible for managing the editing state of a task.
// It handles text fields, categories, tags, and image selection/removal.
class EditTaskViewModel extends ChangeNotifier {
  // The original task before editing, used as the data source
  final TaskModel original;

  // Controllers for text inputs
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  final tagCtrl = TextEditingController();

  // Internal state of selected category and tags
  late TaskCategory _selectedCategory;
  late List<String> _tags;

  // Stores the existing image URL from Firestore (if any)
  String? _currentImageUrl;

  // Stores a newly picked image (if any)
  Uint8List? _newImageBytes;

  // Flag to indicate whether the existing image should be removed entirely
  bool _removeImage = false;

  // Constructor initializes controllers and loads original task data
  EditTaskViewModel(this.original) {
    titleCtrl = TextEditingController(text: original.title);
    descCtrl = TextEditingController(text: original.description);
    _selectedCategory = original.category;
    _tags = List<String>.from(original.tags);
    _currentImageUrl = original.imageUrl;
  }

  // Public getters to expose immutable state to the UI
  TaskCategory get selectedCategory => _selectedCategory;
  List<String> get tags => List.unmodifiable(_tags);
  String? get currentImageUrl => _currentImageUrl;
  Uint8List? get newImageBytes => _newImageBytes;

  // Indicates whether the task currently has an image (stored or newly picked)
  bool get hasImage =>
      (_currentImageUrl != null && !_removeImage) || _newImageBytes != null;

  // Updates the selected category
  void setCategory(TaskCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }

  // Adds a tag if not empty and not duplicated
  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;
    _tags.add(trimmed);
    tagCtrl.clear();
    notifyListeners();
  }

  // Removes an existing tag
  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  // Lets the user pick a new image from gallery, compress it and store its bytes
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null) return;

    _newImageBytes = await file.readAsBytes();
    _removeImage = false; // ensure we don't delete image accidentally
    notifyListeners();
  }

  // Marks the image as removed (no image should remain after update)
  void removeImage() {
    _newImageBytes = null;
    _removeImage = true;
    notifyListeners();
  }

  // Applies modifications and sends the update request to TaskService
  Future<bool> update(TaskService service) async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return false;

    // Determine whether to keep or clear the existing image URL
    final imageUrlToKeep = _removeImage ? null : _currentImageUrl;

    // Prepare updated model
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

    // Perform Firestore + Storage update
    await service.updateTask(
      updatedTask,
      imageBytes: _newImageBytes,
      removeImage: _removeImage,
    );
    return true;
  }

  @override
  void dispose() {
    // Dispose controllers to release memory
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }
}