import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/widgets/task_tile.dart';

void main() {
  testWidgets(
    'TaskTile displays title, category and optional image',
    (WidgetTester tester) async {
      // Sample task with image and tags
      final task = TaskModel(
        id: '1',
        userId: 'u1',
        title: 'Buy milk',
        description: 'From the supermarket',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        category: TaskCategory.shopping,
        tags: const ['urgent', 'home'],
        imageUrl: 'https://example.com/image.jpg',
      );

      // mockNetworkImagesFor intercepts all Image.network calls
      // and returns a mocked image instead of doing a real HTTP call.
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TaskTile(task: task),
            ),
          ),
        );

        // Verify the title is shown
        expect(find.text('Buy milk'), findsOneWidget);

        // Verify category display name is shown
        expect(find.text('Shopping'), findsOneWidget);

        // Verify description is shown
        expect(find.text('From the supermarket'), findsOneWidget);

        // Verify tags are shown
        expect(find.text('#urgent'), findsOneWidget);
        expect(find.text('#home'), findsOneWidget);

        // An Image widget should be present (network image mocked)
        expect(find.byType(Image), findsWidgets);
      });
    },
  );
}
