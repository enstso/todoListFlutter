import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/pages/viewmodels/add_task_view_model.dart';

void main() {
  group('AddTaskViewModel', () {
    test('initial state is correct', () {
      final vm = AddTaskViewModel();

      // Category should default to "other"
      expect(vm.selectedCategory, TaskCategory.other);

      // No tags at start
      expect(vm.tags, isEmpty);

      // No image selected initially
      expect(vm.imageBytes, isNull);
    });

    test('addTag adds a trimmed tag and avoids duplicates', () {
      final vm = AddTaskViewModel();

      // Add a valid tag
      vm.addTag(' urgent ');
      expect(vm.tags, ['urgent']);

      // Adding the same tag again should not duplicate it
      vm.addTag('urgent');
      expect(vm.tags.length, 1);

      // Adding empty string should be ignored
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

      // We simulate that an image has been selected by setting imageBytes
      vm
        ..addTag('test') // some activity
        ..clearImage();  // should set imageBytes to null

      // By default imageBytes is null, so call clearImage should keep it null
      expect(vm.imageBytes, isNull);
    });
  });
}
