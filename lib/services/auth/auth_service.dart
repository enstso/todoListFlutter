import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // FirebaseAuth used to interact with Firebase Authentication API
  final FirebaseAuth _auth;
  final FirebaseFirestore? _db;

  // constructor so we can inject a mock in tests
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  // Stream that emits the current authentication state
  // Useful to detect sign-in/sign-out in real time
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Returns the currently authenticated user, or null if not signed in
  User? get currentUser => _auth.currentUser;

  // Attempts to sign in a user with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // Return authenticated user
    } on FirebaseAuthException catch (e) {
      // Convert Firebase-specific errors to a general exception
      throw Exception(e.message ?? 'Authentication failed');
    }
  }

  // Creates a new user account using email and password
  Future<User?> signUp(String email, String password) async {
    try {
      // Create the user in Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      // If user creation failed for some reason, throw a generic error
      if (user == null) {
        throw Exception('Sign up failed: user is null');
      }

      // Store basic user information in Firestore "users" collection.
      // This is required so we can:
      //  - search users by email (for assignment)
      //  - validate that an email belongs to an existing user
      await _db?.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': Timestamp.now(),
        // You can add more fields later (displayName, photoUrl, etc.)
      });

      // Return newly created user
      return user;
    } on FirebaseAuthException catch (e) {
      // Throw a clean error message in case of failure
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  // Signs out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
