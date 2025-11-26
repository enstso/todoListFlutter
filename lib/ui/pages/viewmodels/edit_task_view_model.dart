import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/user/user_service.dart';

/// ViewModel responsible for managing the editing state of a task.
/// It handles text fields, categories, tags, assignee and image selection/removal.
class EditTaskViewModel extends ChangeNotifier {
  /// Original task before editing (used as base data).
  final TaskModel original;

  /// Controllers for text inputs.
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;
  final TextEditingController tagCtrl = TextEditingController();

  /// Controller for the assignee field (email).
  late final TextEditingController assignedToCtrl;

  /// Internal state of selected category and tags.
  late TaskCategory _selectedCategory;
  late List<String> _tags;

  /// Stores the existing image URL from Firestore (if any).
  String? _currentImageUrl;

  /// Stores a newly picked image (if any).
  Uint8List? _newImageBytes;

  /// Indicates that the existing image should be removed.
  bool _removeImage = false;

  /// Assignee validation:
  ///  - validatedAssigneeUid: UID of the user found for this email (if any)
  ///  - isCheckingAssignee: true while querying Firestore
  ///  - assigneeError: error message when email is invalid / not found
  String? validatedAssigneeUid;
  bool isCheckingAssignee = false;
  String? assigneeError;

  /// Initializes controllers and loads original task data.
  EditTaskViewModel(this.original) {
    titleCtrl = TextEditingController(text: original.title);
    descCtrl = TextEditingController(text: original.description);
    assignedToCtrl = TextEditingController(text: original.assignedTo ?? '');
    _selectedCategory = original.category;
    _tags = List<String>.from(original.tags);
    _currentImageUrl = original.imageUrl;

    // If the original task is already assigned, keep its UID as validated.
    validatedAssigneeUid = original.assignedToUid;
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

  /// Picks a new image and stores it in memory.
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

  /// Removes the existing image (either stored or newly picked).
  void removeImage() {
    _newImageBytes = null;
    _removeImage = true;
    _currentImageUrl = null;
    notifyListeners();
  }

  /// Clears assignee validation state when user edits / clears the field.
  void clearAssigneeValidation() {
    validatedAssigneeUid = null;
    assigneeError = null;
    isCheckingAssignee = false;
    notifyListeners();
  }

  /// Validates the assignee email by checking that a user exists in Firestore.
  Future<void> checkAssigneeEmail(
    UserService userService, {
    required String? currentUserEmail,
  }) async {
    final email = assignedToCtrl.text.trim().toLowerCase();

    if (email.isEmpty) {
      clearAssigneeValidation();
      return;
    }

    // Prevent assigning task to yourself
    if (currentUserEmail != null &&
        email == currentUserEmail.toLowerCase().trim()) {
      validatedAssigneeUid = null;
      assigneeError = "You can't assign a task to yourself";
      isCheckingAssignee = false;
      notifyListeners();
      return;
    }

    // Start loading state
    isCheckingAssignee = true;
    assigneeError = null;
    validatedAssigneeUid = null;
    notifyListeners();

    try {
      final userDoc = await userService.getUserByEmail(email);

      isCheckingAssignee = false;

      if (userDoc == null) {
        assigneeError = 'No user found with this email';
        validatedAssigneeUid = null;
      } else {
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

  /// Applies modifications and sends the update request to [TaskService].
  ///
  /// Returns false if validation fails (e.g. empty title or invalid assignee).
  Future<bool> update(TaskService service) async {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) return false;

    final assigneeText = assignedToCtrl.text.trim();
    String? assignedToEmail = assigneeText.isEmpty ? null : assigneeText;

    // If there is an assignee email, we expect a validated UID.
    // Otherwise, the user must press the "check" button first.
    String? assignedToUid;
    if (assignedToEmail != null) {
      // If user didn't revalidate but email is unchanged, keep original UID.
      if (validatedAssigneeUid == null &&
          assignedToEmail == original.assignedTo &&
          original.assignedToUid != null) {
        assignedToUid = original.assignedToUid;
      } else {
        assignedToUid = validatedAssigneeUid;
      }

      // If still null → validation failed.
      if (assignedToUid == null) {
        assigneeError = 'Please validate the assignee email before saving';
        notifyListeners();
        return false;
      }
    }

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
      assignedTo: assignedToEmail,
      assignedToUid: assignedToUid,
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
    assignedToCtrl.dispose();
    super.dispose();
  }
}
