import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/ui/widgets/task_tile.dart';

void main() {
  testWidgets(
    'TaskTile displays title, category, description, tags and optional image',
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

      // mockNetworkImagesFor intercepts all Image.network calls so that
      // no real HTTP request is performed during the widget test.
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: TaskTile(task: task)),
          ),
        );

        // Title should be visible
        expect(find.text('Buy milk'), findsOneWidget);

        // Category display name should be visible
        expect(find.text('Shopping'), findsOneWidget);

        // Description should be visible
        expect(find.text('From the supermarket'), findsOneWidget);

        // Tags should be rendered as text with "#"
        expect(find.text('#urgent'), findsOneWidget);
        expect(find.text('#home'), findsOneWidget);

        // At least one Image widget should be present (the mocked network image)
        expect(find.byType(Image), findsWidgets);
      });
    },
  );

  testWidgets('TaskTile displays assignee text when assignedTo is set', (
    WidgetTester tester,
  ) async {
    // Task with an assignee (assignedTo field is filled)
    final task = TaskModel(
      id: '2',
      userId: 'u1',
      title: 'Share document',
      description: 'Send spec to teammate',
      isCompleted: false,
      createdAt: DateTime(2024, 2, 1),
      category: TaskCategory.work,
      tags: const [],
      imageUrl: null,
      assignedTo: 'teammate@example.com',
    );

    // No network image used here, but we still keep the wrapper for consistency
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TaskTile(task: task)),
        ),
      );

      // The full text rendered in the tile is: "Assigned to: teammate@example.com"
      expect(find.text('Assigned to: teammate@example.com'), findsOneWidget);
    });
  });
}
