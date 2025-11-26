import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/pages/viewmodels/add_task_view_model.dart';
import 'package:todo_list/services/user/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_task_view_model_test.mocks.dart';

/// We mock UserService and DocumentSnapshot for assignee validation.
@GenerateMocks([UserService, DocumentSnapshot<Map<String, dynamic>>])
void main() {
  group('AddTaskViewModel', () {
    test('initial state is correct', () {
      final vm = AddTaskViewModel();

      expect(vm.selectedCategory, TaskCategory.other);
      expect(vm.tags, isEmpty);
      expect(vm.imageBytes, isNull);

      // Assignee defaults
      expect(vm.assignedToCtrl.text, '');
      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, isNull);
      expect(vm.isCheckingAssignee, isFalse);
    });

    test('addTag adds a trimmed tag and avoids duplicates', () {
      final vm = AddTaskViewModel();

      vm.addTag(' urgent ');
      expect(vm.tags, ['urgent']);

      vm.addTag('urgent');
      expect(vm.tags.length, 1);

      vm.addTag('   ');
      expect(vm.tags.length, 1);
    });

    test('removeTag removes an existing tag', () {
      final vm = AddTaskViewModel();

      vm.addTag('work');
      vm.addTag('home');

      vm.removeTag('work');

      expect(vm.tags, ['home']);
    });

    test('clearImage sets imageBytes to null', () {
      final vm = AddTaskViewModel();

      vm.addTag('test');
      vm.clearImage();

      expect(vm.imageBytes, isNull);
    });

    // ----------------------------------------------------------------------
    // ASSIGNEE TESTS
    // ----------------------------------------------------------------------

    test(
      'checkAssigneeEmail clears validation if email field is empty',
      () async {
        final vm = AddTaskViewModel();
        final mockUserService = MockUserService();

        vm.assignedToCtrl.text = ''; // Empty email

        vm.validatedAssigneeUid = 'old';
        vm.assigneeError = 'Old error';
        vm.isCheckingAssignee = true;

        await vm.checkAssigneeEmail(
          mockUserService,
          currentUserEmail: 'me@example.com', // can be anything
        );

        expect(vm.validatedAssigneeUid, isNull);
        expect(vm.assigneeError, isNull);
        expect(vm.isCheckingAssignee, isFalse);

        verifyNever(mockUserService.getUserByEmail(any));
      },
    );

    test(
      'checkAssigneeEmail sets error when no user exists for this email',
      () async {
        final vm = AddTaskViewModel();
        final mockUserService = MockUserService();

        vm.assignedToCtrl.text = 'unknown@example.com';

        when(
          mockUserService.getUserByEmail('unknown@example.com'),
        ).thenAnswer((_) async => null);

        await vm.checkAssigneeEmail(
          mockUserService,
          currentUserEmail: 'me@example.com',
        );

        expect(vm.isCheckingAssignee, isFalse);
        expect(vm.validatedAssigneeUid, isNull);
        expect(vm.assigneeError, 'No user found with this email');
      },
    );

    test('checkAssigneeEmail validates user and extracts UID', () async {
      final vm = AddTaskViewModel();
      final mockUserService = MockUserService();

      vm.assignedToCtrl.text = 'USER@example.com';

      final mockDoc =
          MockDocumentSnapshot<Map<String, dynamic>>(); // correct generic
      when(mockDoc.id).thenReturn('uid-123');

      when(
        mockUserService.getUserByEmail('user@example.com'),
      ).thenAnswer((_) async => mockDoc);

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      expect(vm.isCheckingAssignee, isFalse);
      expect(vm.assigneeError, isNull);
      expect(vm.validatedAssigneeUid, 'uid-123');
    });

    test('checkAssigneeEmail prevents assigning task to yourself', () async {
      final vm = AddTaskViewModel();
      final mockUserService = MockUserService();

      vm.assignedToCtrl.text = 'me@example.com';

      await vm.checkAssigneeEmail(
        mockUserService,
        currentUserEmail: 'me@example.com',
      );

      // Should not call Firestore at all
      verifyNever(mockUserService.getUserByEmail(any));

      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, 'You can\'t assign a task to yourself');
      expect(vm.isCheckingAssignee, isFalse);
    });

    test('clearAssignee resets validation state', () {
      final vm = AddTaskViewModel();

      vm.validatedAssigneeUid = 'uid-old';
      vm.assigneeError = 'Some error';

      vm.clearAssigneeValidation();

      expect(vm.validatedAssigneeUid, isNull);
      expect(vm.assigneeError, isNull);
    });
  });
}
