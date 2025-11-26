import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/user/user_service.dart';

/// ViewModel responsible for managing the state of the "Add Task" form.
/// It handles title, description, category, tags, assignee and optional image.
class AddTaskViewModel extends ChangeNotifier {
  // Text controllers for task fields.
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final tagCtrl = TextEditingController();

  /// Text field used to enter the assignee email.
  final assignedToCtrl = TextEditingController();

  /// Assignee validation:
  ///  - validatedAssigneeUid: UID of the user found for this email (if any)
  ///  - isCheckingAssignee: true while Firestore is being queried
  ///  - assigneeError: error message if email is invalid / user not found
  String? validatedAssigneeUid;
  bool isCheckingAssignee = false;
  String? assigneeError;

  // Category state.
  TaskCategory _selectedCategory = TaskCategory.other;

  // Tags of the task.
  final List<String> _tags = [];

  // In-memory image bytes when the user selects an image.
  Uint8List? _imageBytes;

  TaskCategory get selectedCategory => _selectedCategory;
  List<String> get tags => List.unmodifiable(_tags);
  Uint8List? get imageBytes => _imageBytes;

  /// Updates the selected category and notifies listeners.
  void setCategory(TaskCategory c) {
    _selectedCategory = c;
    notifyListeners();
  }

  /// Adds a tag if it is not empty and not already present.
  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (_tags.contains(trimmed)) return;
    _tags.add(trimmed);
    tagCtrl.clear();
    notifyListeners();
  }

  /// Removes a tag from the list.
  void removeTag(String tag) {
    _tags.remove(tag);
    notifyListeners();
  }

  /// Picks an image from the gallery and stores its bytes.
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

  /// Clears the current image.
  void clearImage() {
    _imageBytes = null;
    notifyListeners();
  }

  /// Clears assignee validation state (used when user edits / clears the field).
  void clearAssigneeValidation() {
    validatedAssigneeUid = null;
    assigneeError = null;
    isCheckingAssignee = false;
    notifyListeners();
  }

  /// Validates the assignee email by checking that a user exists in Firestore.
  /// Uses [UserService.getUserByEmail] to query the "users" collection.
  Future<void> checkAssigneeEmail(
    UserService service, {
    required String? currentUserEmail,
  }) async {
    final email = assignedToCtrl.text.trim().toLowerCase();

    // If the field is empty, we just reset validation state.
    if (email.isEmpty) {
      clearAssigneeValidation();
      return;
    }

    if (currentUserEmail != null &&
        email == currentUserEmail.toLowerCase().trim()) {
      validatedAssigneeUid = null;
      isCheckingAssignee = false;
      assigneeError = "You can't assign a task to yourself";
      notifyListeners();
      return;
    }

    // Start loading state
    isCheckingAssignee = true;
    assigneeError = null;
    validatedAssigneeUid = null;
    notifyListeners();

    try {
      final userDoc = await service.getUserByEmail(email);

      isCheckingAssignee = false;

      if (userDoc == null) {
        // No user found for this email.
        assigneeError = 'No user found with this email';
        validatedAssigneeUid = null;
      } else {
        // Valid user found.
        validatedAssigneeUid = userDoc.id;
        assigneeError = null;
      }
    } catch (_) {
      isCheckingAssignee = false;
      assigneeError = 'Error while checking user';
      validatedAssigneeUid = null;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    tagCtrl.dispose();
    assignedToCtrl.dispose();
    super.dispose();
  }
}
