import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:image_picker/image_picker.dart';

class AddTaskViewModel extends ChangeNotifier {
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.other;
  final List<String> _tags = [];

  Uint8List? _imageBytes;

  TaskCategory get selectedCategory => _selectedCategory;
  List<String> get tags => List.unmodifiable(_tags);
  Uint8List? get imageBytes => _imageBytes;

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

    _imageBytes = await file.readAsBytes();
    notifyListeners();
  }

  void clearImage() {
    _imageBytes = null;
    notifyListeners();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    super.dispose();
  }
}
