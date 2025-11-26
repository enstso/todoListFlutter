import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

import 'task_service_test.mocks.dart';

/// Mock only the Firebase singletons (Auth, Firestore, Storage).
/// For CollectionReference/DocumentReference we use simple fake classes.
@GenerateMocks([FirebaseAuth, User, FirebaseFirestore, FirebaseStorage])

/// Fake "tasks" CollectionReference
/// We only care that it implements CollectionReference<Map<String, dynamic>>
class FakeTasksCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

void main() {
  group('TaskService (auth guard)', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseStorage mockStorage;
    late FakeTasksCollection fakeCollection;

    late TaskService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockStorage = MockFirebaseStorage();

      fakeCollection = FakeTasksCollection();

      /// When Firestore calls `.collection("tasks")`, we return our fake collection.
      when(mockFirestore.collection('tasks')).thenReturn(fakeCollection);

      /// Create TaskService with injected mocks
      service = TaskService(
        auth: mockAuth,
        firestore: mockFirestore,
        storage: mockStorage,
      );
    });

    test('addTask throws if user not authenticated', () async {
      // Arrange: no logged-in user → auth guard should reject
      when(mockAuth.currentUser).thenReturn(null);

      final task = TaskModel(
        id: '_',
        userId: '_',
        title: 'Test',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        category: TaskCategory.other,
        tags: const [],
        assignedTo: "someone@example.com", // assignee supported
      );

      // Assert: calling addTask must throw
      expect(
        () => service.addTask(task),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not authenticated'),
          ),
        ),
      );
    });

    test('updateTask throws if user not authenticated', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      final task = TaskModel(
        id: 't1',
        userId: 'u1',
        title: 'Test',
        description: '',
        isCompleted: false,
        createdAt: DateTime.now(),
        category: TaskCategory.other,
        tags: const [],
        assignedTo: null, // no assignee
      );

      // Act + Assert
      expect(
        () => service.updateTask(task),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not authenticated'),
          ),
        ),
      );
    });

    test('deleteTask throws if user not authenticated', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Assert
      expect(
        () => service.deleteTask('t1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('User not authenticated'),
          ),
        ),
      );
    });
  });
}
