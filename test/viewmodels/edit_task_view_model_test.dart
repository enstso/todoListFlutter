import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';
import 'package:todo_list/ui/pages/viewmodels/edit_task_view_model.dart';

import 'edit_task_view_model_test.mocks.dart';

@GenerateMocks([TaskService])
void main() {
  group('EditTaskViewModel', () {
    late TaskModel original;
    late MockTaskService mockService;

    setUp(() {
      // Create a sample original task
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
      );

      mockService = MockTaskService();
    });

    test('initial fields are correctly populated from original task', () {
      final vm = EditTaskViewModel(original);

      expect(vm.titleCtrl.text, 'Original title');
      expect(vm.descCtrl.text, 'Original description');
      expect(vm.selectedCategory, TaskCategory.work);
      expect(vm.tags, ['office']);
      expect(vm.currentImageUrl, 'https://example.com/image.jpg');
      expect(vm.hasImage, isTrue);
    });

    test('update returns false and does not call service if title is empty', () async {
      final vm = EditTaskViewModel(original);

      // Force empty title
      vm.titleCtrl.text = '   ';

      final result = await vm.update(mockService);

      expect(result, isFalse);
      // Service must not be called when title is empty
      verifyNever(mockService.updateTask(any, imageBytes: anyNamed('imageBytes'), removeImage: anyNamed('removeImage')));
    });

    test('update calls service with updated task when title is valid', () async {
      final vm = EditTaskViewModel(original);

      // Change title and category
      vm.titleCtrl.text = 'Updated title';
      vm.setCategory(TaskCategory.personal);

      // Call update
      when(mockService.updateTask(any,
              imageBytes: anyNamed('imageBytes'),
              removeImage: anyNamed('removeImage')))
          .thenAnswer((_) async {});

      final result = await vm.update(mockService);

      expect(result, isTrue);

      // Capture the TaskModel argument passed to service.updateTask
      final captured = verify(
        mockService.updateTask(
          captureAny,
          imageBytes: captureAnyNamed('imageBytes'),
          removeImage: captureAnyNamed('removeImage'),
        ),
      ).captured;

      final updatedTask = captured[0] as TaskModel;
      final imageBytes = captured[1];      // should be null in this test
      final removeImageFlag = captured[2]; // should be false by default

      // Verify that the updated task keeps same id/user but new title/category
      expect(updatedTask.id, original.id);
      expect(updatedTask.userId, original.userId);
      expect(updatedTask.title, 'Updated title');
      expect(updatedTask.category, TaskCategory.personal);

      // Image URL should be kept (no removeImage called and no new imageBytes)
      expect(updatedTask.imageUrl, original.imageUrl);
      expect(imageBytes, isNull);
      expect(removeImageFlag, isFalse);
    });

    test('removeImage clears imageUrl and sets removeImage flag', () async {
      final vm = EditTaskViewModel(original);

      // User decides to remove existing image
      vm.removeImage();

      when(mockService.updateTask(any,
              imageBytes: anyNamed('imageBytes'),
              removeImage: anyNamed('removeImage')))
          .thenAnswer((_) async {});

      final result = await vm.update(mockService);

      expect(result, isTrue);

      final captured = verify(
        mockService.updateTask(
          captureAny,
          imageBytes: captureAnyNamed('imageBytes'),
          removeImage: captureAnyNamed('removeImage'),
        ),
      ).captured;

      final updatedTask = captured[0] as TaskModel;
      final imageBytes = captured[1];
      final removeImageFlag = captured[2];

      // Image URL should be null when removeImage was requested
      expect(updatedTask.imageUrl, isNull);
      expect(imageBytes, isNull);
      expect(removeImageFlag, isTrue);
    });
  });
}
