import 'package:cloud_firestore/cloud_firestore.dart';

/// Small abstraction over the "users" collection in Firestore.
/// Used to:
///  - find a user by email
///  - search emails for assignee autocomplete
class UserService {
  final CollectionReference<Map<String, dynamic>> _users;

  /// Allow injecting a [FirebaseFirestore] instance for testing.
  UserService({FirebaseFirestore? firestore})
      : _users = (firestore ?? FirebaseFirestore.instance)
            .collection('users');

  /// Returns the first user document matching the given email,
  /// or null if no user is found.
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByEmail(
    String email,
  ) async {
    final query = await _users
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  /// Returns a list of matching emails for autocomplete.
  /// If [query] is empty, returns an empty list without hitting Firestore.
  Future<List<String>> searchEmails(String query) async {
    if (query.isEmpty) return [];

    final snapshot = await _users
        .where('email', isGreaterThanOrEqualTo: query)
        .where('email', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs.map((d) => d['email'] as String).toList();
  }
}
