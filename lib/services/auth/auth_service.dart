import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // FirebaseAuth used to interact with Firebase Authentication API
  final FirebaseAuth _auth;

  // constructor so we can inject a mock in tests
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

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
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user; // Return newly created user
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
