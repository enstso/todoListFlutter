import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:todo_list/models/task_model.dart';
import 'package:todo_list/services/task/task_service.dart';

import 'task_service_test.mocks.dart';

/// We mock only the Firebase singletons here.
/// We will hand-roll a fake CollectionReference below.
@GenerateMocks([
  FirebaseAuth,
  User,
  FirebaseFirestore,
  FirebaseStorage,
])

/// Simple mock class for CollectionReference<Map<String, dynamic>>
/// so we don't depend on a generated `MockCollectionReference`.
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

      // Stub Firestore.collection('tasks') to return our fake collection
      fakeCollection = FakeTasksCollection();
      when(mockFirestore.collection('tasks')).thenReturn(fakeCollection);

      // Now TaskService can be created safely (it calls firestore.collection in ctor)
      service = TaskService(
        auth: mockAuth,
        firestore: mockFirestore,
        storage: mockStorage,
      );
    });

    test('addTask throws if user not authenticated', () async {
      // No current user
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
      );

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
      );

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
      when(mockAuth.currentUser).thenReturn(null);

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
