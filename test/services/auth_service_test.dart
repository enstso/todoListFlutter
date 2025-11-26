import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:todo_list/services/auth/auth_service.dart';

import 'auth_service_test.mocks.dart';

/// Generate mocks for the FirebaseAuth & Firestore APIs we use.
@GenerateMocks([
  FirebaseAuth,
  UserCredential,
  User,
  FirebaseFirestore,
  CollectionReference<Map<String, dynamic>>,
  DocumentReference,
])
void main() {
  group('AuthService', () {
    late MockFirebaseAuth mockAuth;
    late MockUserCredential mockCredential;
    late MockUser mockUser;

    late MockFirebaseFirestore mockFirestore;
    late MockCollectionReference<Map<String, dynamic>> mockUsersCollection;
    late MockDocumentReference<Map<String, dynamic>> mockUserDoc;

    late AuthService service;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockCredential = MockUserCredential();
      mockUser = MockUser();

      mockFirestore = MockFirebaseFirestore();
      mockUsersCollection = MockCollectionReference();
      mockUserDoc = MockDocumentReference();

      // Stub Firestore access: firestore.collection('users').doc(uid).set(...)
      when(mockFirestore.collection('users')).thenReturn(mockUsersCollection);
      when(mockUsersCollection.doc(any)).thenReturn(mockUserDoc);
      when(mockUserDoc.set(any)).thenAnswer((_) async {});

      // Inject mocks into AuthService
      service = AuthService(auth: mockAuth, firestore: mockFirestore);
    });

    test('signIn returns user on success', () async {
      // Arrange
      when(
        mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);

      // Act
      final user = await service.signIn('test@example.com', 'password123');

      // Assert
      expect(user, mockUser);
      verify(
        mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test(
      'signIn throws Exception with message when FirebaseAuthException occurs',
      () async {
        // Arrange
        when(
          mockAuth.signInWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          ),
        );

        // Act & Assert
        expect(
          () => service.signIn('test@example.com', 'badpass'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('User not found'),
            ),
          ),
        );
      },
    );

    test('signUp returns user on success and writes to Firestore', () async {
      // Arrange
      when(
        mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockCredential);

      when(mockCredential.user).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('uid-123');
      when(mockUser.email).thenReturn('new@example.com');

      // Act
      final user = await service.signUp('new@example.com', 'password123');

      // Assert
      expect(user, mockUser);

      verify(
        mockAuth.createUserWithEmailAndPassword(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).called(1);

      // Firestore must be called
      verify(mockFirestore.collection('users')).called(1);
      verify(mockUsersCollection.doc('uid-123')).called(1);
      verify(
        mockUserDoc.set(
          argThat(
            allOf(
              isA<Map<String, dynamic>>(),
              containsPair('uid', 'uid-123'),
              containsPair('email', 'new@example.com'),
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'signUp throws Exception with message when FirebaseAuthException occurs',
      () async {
        // Arrange
        when(
          mockAuth.createUserWithEmailAndPassword(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email already used',
          ),
        );

        // Act & Assert
        expect(
          () => service.signUp('dup@example.com', 'password123'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email already used'),
            ),
          ),
        );
      },
    );

    test('signOut calls FirebaseAuth.signOut', () async {
      // Arrange
      when(mockAuth.signOut()).thenAnswer((_) async {});

      // Act
      await service.signOut();

      // Assert
      verify(mockAuth.signOut()).called(1);
    });
  });
}
