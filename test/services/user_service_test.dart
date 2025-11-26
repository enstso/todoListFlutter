import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_list/services/user/user_service.dart';

import 'user_service_test.mocks.dart';

/// We mock Firestore core types that UserService interacts with:
///  - FirebaseFirestore
///  - CollectionReference<Map<String,dynamic>>
///  - Query<Map<String,dynamic>>
///  - QuerySnapshot<Map<String,dynamic>>
///  - QueryDocumentSnapshot<Map<String,dynamic>>  <-- important for docs list
@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  Query,
  QuerySnapshot,
  QueryDocumentSnapshot,
])
void main() {
  // Firestore mocks
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
  late MockQuery<Map<String, dynamic>> mockQuery;
  late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;

  // Single doc mock used in getUserByEmail
  late MockQueryDocumentSnapshot<Map<String, dynamic>> mockDoc;

  late UserService service;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockUsersCollection = MockCollectionReference<Map<String, dynamic>>();
    mockQuery = MockQuery<Map<String, dynamic>>();
    mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
    mockDoc = MockQueryDocumentSnapshot<Map<String, dynamic>>();

    // Firestore.collection("users") → mockUsersCollection
    when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);

    // Inject mocked Firestore into our service
    service = UserService(firestore: mockFirestore);
  });

  group('getUserByEmail', () {
    test('returns first document when one exists', () async {
      // Arrange:
      // users.where('email', isEqualTo: 'user@example.com') → mockQuery
      when(
        mockUsersCollection.where(
          'email',
          isEqualTo: 'user@example.com',
        ),
      ).thenReturn(mockQuery);

      // limit(1) → same query
      when(mockQuery.limit(1)).thenReturn(mockQuery);

      // get() → mockQuerySnapshot
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      // docs → a List<QueryDocumentSnapshot<Map<String,dynamic>>>
      when(mockQuerySnapshot.docs).thenReturn([mockDoc]);

      // Give the doc an id
      when(mockDoc.id).thenReturn('uid-123');

      // Act
      final doc = await service.getUserByEmail('user@example.com');

      // Assert
      expect(doc, isNotNull);
      expect(doc!.id, 'uid-123');

      verify(mockUsersCollection.where(
        'email',
        isEqualTo: 'user@example.com',
      )).called(1);
      verify(mockQuery.limit(1)).called(1);
      verify(mockQuery.get()).called(1);
    });

    test('returns null when no document is found', () async {
      // Arrange
      when(
        mockUsersCollection.where(
          'email',
          isEqualTo: 'unknown@example.com',
        ),
      ).thenReturn(mockQuery);
      when(mockQuery.limit(1)).thenReturn(mockQuery);
      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      // docs is an empty list
      when(mockQuerySnapshot.docs).thenReturn(<MockQueryDocumentSnapshot<Map<String, dynamic>>>[]);

      // Act
      final doc = await service.getUserByEmail('unknown@example.com');

      // Assert
      expect(doc, isNull);
    });
  });

  group('searchEmails', () {
    test('returns empty list when query is empty', () async {
      // When query is empty, service should return [] and not hit Firestore.
      final result = await service.searchEmails('');
      expect(result, isEmpty);

      // Optional: you can skip verifications here to avoid matcher noise.
    });

    test('returns list of matching emails', () async {
      const q = 'ali';

      // First where(... isGreaterThanOrEqualTo ...)
      when(
        mockUsersCollection.where(
          'email',
          isGreaterThanOrEqualTo: q,
        ),
      ).thenReturn(mockQuery);

      // Second where(... isLessThanOrEqualTo ...)
      when(
        mockQuery.where(
          'email',
          isLessThanOrEqualTo: '$q\uf8ff',
        ),
      ).thenReturn(mockQuery);

      when(mockQuery.get()).thenAnswer((_) async => mockQuerySnapshot);

      // docs: list of QueryDocumentSnapshot
      final doc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
      final doc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

      // Simulate Firestore field access: doc['email']
      when(doc1['email']).thenReturn('alice@example.com');
      when(doc2['email']).thenReturn('ali.bob@example.com');

      when(mockQuerySnapshot.docs).thenReturn([doc1, doc2]);

      // Act
      final emails = await service.searchEmails(q);

      // Assert
      expect(emails, ['alice@example.com', 'ali.bob@example.com']);

      verify(mockUsersCollection.where(
        'email',
        isGreaterThanOrEqualTo: q,
      )).called(1);

      verify(mockQuery.where(
        'email',
        isLessThanOrEqualTo: '$q\uf8ff',
      )).called(1);

      verify(mockQuery.get()).called(1);
    });
  });
}
