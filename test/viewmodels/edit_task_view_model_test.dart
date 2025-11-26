import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/services/user/user_service.dart';
import 'package:todo_list/ui/pages/viewmodels/edit_task_view_model.dart';

import 'edit_task_view_model_test.mocks.dart';

/// We mock:
///  - TaskService : to verify update() calls
///  - UserService : to test assignee email validation
///  - DocumentSnapshot<Map<String,dynamic>> : returned by UserService.getUserByEmail
@GenerateMocks([
  TaskService,
  UserService,
  DocumentSnapshot, // generic will be used as MockDocumentSnapshot<Map<String,dynamic>>
])
void main() {
  group('EditTaskViewModel', () {
    late TaskModel original;
    late MockTaskService mockTaskService;
    late MockUserService mockUserService;

    setUp(() {
      // Sample original task
      original = TaskModel(
        id: '1',
        userId: 'u1',
        title: 'Original title',
        description: 'Original description',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        category: TaskCategory.work,
        tags: const ['office'],
        imageUrl: 'https://example.com/image.jpg',
        // assignedTo: null by default
      );

      mockTaskService = MockTaskService();
      mockUserService = MockUserService();
    });

    // -------------------------------------------------------------------------
    // BASIC STATE / UPDATE TESTS
    // -------------------------------------------------------------------------

    test('initial fields are correctly populated from original task', () {
      final vm = EditTaskViewModel(original);

      expect(vm.titleCtrl.text, 'Original title');
      expect(vm.descCtrl.text, 'Original description');
      expect(vm.selectedCategory, TaskCategory.work);
      expect(vm.tags, ['office']);
      expect(vm.currentImageUrl, 'https://example.com/image.jpg');
      expect(vm.hasImage, isTrue);

      // Assignee-related initial state
      expect(vm.assignedToCtrl.text, '');
      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, isNull);
      expect(vm.isCheckingAssignee, isFalse);
    });

    test('update returns false and does not call service if title is empty',
        () async {
      final vm = EditTaskViewModel(original);

      // Force empty title.
      vm.titleCtrl.text = '   ';

      final result = await vm.update(mockTaskService);

      expect(result, isFalse);

      // Service must not be called when title is empty.
      verifyNever(
        mockTaskService.updateTask(
          any,
          imageBytes: anyNamed('imageBytes'),
          removeImage: anyNamed('removeImage'),
        ),
      );
    });

    test('update calls service with updated task when title is valid',
        () async {
      final vm = EditTaskViewModel(original);

      vm.titleCtrl.text = 'Updated title';
      vm.setCategory(TaskCategory.personal);

      when(
        mockTaskService.updateTask(
          any,
          imageBytes: anyNamed('imageBytes'),
          removeImage: anyNamed('removeImage'),
        ),
      ).thenAnswer((_) async {});

      final result = await vm.update(mockTaskService);
      expect(result, isTrue);

      final captured = verify(
        mockTaskService.updateTask(
          captureAny,
          imageBytes: captureAnyNamed('imageBytes'),
          removeImage: captureAnyNamed('removeImage'),
        ),
      ).captured;

      final updatedTask = captured[0] as TaskModel;
      final imageBytes = captured[1];
      final removeImageFlag = captured[2];

      // Same id/user, but updated title/category.
      expect(updatedTask.id, original.id);
      expect(updatedTask.userId, original.userId);
      expect(updatedTask.title, 'Updated title');
      expect(updatedTask.category, TaskCategory.personal);

      // Image URL should stay the same in this scenario.
      expect(updatedTask.imageUrl, original.imageUrl);
      expect(imageBytes, isNull);
      expect(removeImageFlag, isFalse);
    });

    test('removeImage clears imageUrl and sets removeImage flag', () async {
      final vm = EditTaskViewModel(original);

      // User chooses to remove the existing image.
      vm.removeImage();

      when(
        mockTaskService.updateTask(
          any,
          imageBytes: anyNamed('imageBytes'),
          removeImage: anyNamed('removeImage'),
        ),
      ).thenAnswer((_) async {});

      final result = await vm.update(mockTaskService);
      expect(result, isTrue);

      final captured = verify(
        mockTaskService.updateTask(
          captureAny,
          imageBytes: captureAnyNamed('imageBytes'),
          removeImage: captureAnyNamed('removeImage'),
        ),
      ).captured;

      final updatedTask = captured[0] as TaskModel;
      final imageBytes = captured[1];
      final removeImageFlag = captured[2];

      // Image URL must be null after removal.
      expect(updatedTask.imageUrl, isNull);
      expect(imageBytes, isNull);
      expect(removeImageFlag, isTrue);
    });

    // -------------------------------------------------------------------------
    // ASSIGNEE (EMAIL) TESTS
    // -------------------------------------------------------------------------

    test('checkAssigneeEmail clears validation when email is empty', () async {
      final vm = EditTaskViewModel(original);

      // Previous validation state.
      vm.validatedAssigneeUid = 'old-uid';
      vm.assigneeError = 'Old error';
      vm.isCheckingAssignee = true;

      vm.assignedToCtrl.text = '   ';

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, isNull);
      expect(vm.isCheckingAssignee, isFalse);

      // No call to Firestore when field is empty.
      verifyNever(mockUserService.getUserByEmail(any));
    });

    test('checkAssigneeEmail sets error when no user is found', () async {
      final vm = EditTaskViewModel(original);

      vm.assignedToCtrl.text = 'unknown@example.com';

      when(mockUserService.getUserByEmail('unknown@example.com'))
          .thenAnswer((_) async => null);

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      expect(vm.isCheckingAssignee, isFalse);
      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, 'No user found with this email');

      verify(mockUserService.getUserByEmail('unknown@example.com')).called(1);
    });

    test('checkAssigneeEmail fills validatedAssigneeUid when user exists',
        () async {
      final vm = EditTaskViewModel(original);

      // User types email with weird casing.
      vm.assignedToCtrl.text = 'USER@Example.COM';

      // Typed mock matching DocumentSnapshot<Map<String, dynamic>>.
      final mockDoc = MockDocumentSnapshot<Map<String, dynamic>>();
      when(mockDoc.id).thenReturn('uid-123');

      // getUserByEmail must be called with lowercased email.
      when(mockUserService.getUserByEmail('user@example.com'))
          .thenAnswer((_) async => mockDoc);

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      expect(vm.isCheckingAssignee, isFalse);
      expect(vm.assigneeError, isNull);
      expect(vm.validatedAssigneeUid, 'uid-123');

      verify(mockUserService.getUserByEmail('user@example.com')).called(1);
    });

    test('checkAssigneeEmail prevents assigning task to yourself', () async {
      final vm = EditTaskViewModel(original);

      // User types their own email.
      vm.assignedToCtrl.text = 'me@example.com';

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      // Should not hit Firestore at all.
      verifyNever(mockUserService.getUserByEmail(any));

      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, 'You can\'t assign a task to yourself');
      expect(vm.isCheckingAssignee, isFalse);
    });

    test('clearAssigneeValidation resets validation fields', () {
      final vm = EditTaskViewModel(original);

      vm.validatedAssigneeUid = 'uid-xyz';
      vm.assigneeError = 'Some error';
      vm.isCheckingAssignee = true;

      vm.clearAssigneeValidation();

      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, isNull);
      // isCheckingAssignee is controlled by checkAssigneeEmail, so we don't assert it here.
    });
  });
}
