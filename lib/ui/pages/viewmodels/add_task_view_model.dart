import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:image_picker/image_picker.dart';

// ViewModel responsible for handling the state of the "Add Task" form
class AddTaskViewModel extends ChangeNotifier {
  // Controllers for task title, description and tag input fields
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  // Currently selected category for the new task (default: other)
  TaskCategory _selectedCategory = TaskCategory.other;

  // Internal mutable list of tags
  final List<String> _tags = [];

  // In-memory image bytes picked from gallery (optional)
  Uint8List? _imageBytes;

  // Public getter for the currently selected category
  TaskCategory get selectedCategory => _selectedCategory;

  // Public, unmodifiable view of the tags list
  List<String> get tags => List.unmodifiable(_tags);

  // Public getter for the picked image bytes (if any)
  Uint8List? get imageBytes => _imageBytes;

  // Updates the selected category and notifies listeners (UI rebuild)
  void setCategory(TaskCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }

  // Adds a new tag if it is not empty and not already present
  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;
    _tags.add(trimmed);
    tagCtrl.clear();
    notifyListeners();
  }

  // Removes a tag and notifies listeners
  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  // Opens the image picker, lets the user choose an image from gallery,
  // compresses it and stores its bytes in memory
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (file == null) return;

    _imageBytes = await file.readAsBytes();
    notifyListeners();
  }

  // Clears the currently selected image
  void clearImage() {
    _imageBytes = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Dispose controllers to free resources when ViewModel is destroyed
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }
}
