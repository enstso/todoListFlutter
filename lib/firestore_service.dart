import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TodoItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;

  TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  factory TodoItem.fromMap(Map<String, dynamic> map) {
    return TodoItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      userId: map['userId'] ?? '',
    );
  }

  TodoItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}

class FirestoreService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TodoItem> _todos = [];
  bool _isLoading = false;

  List<TodoItem> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;

  // Écouter les changements de todos en temps réel
  void startListeningToTodos() {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('todos')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _todos = snapshot.docs
              .map((doc) => TodoItem.fromMap(doc.data()))
              .toList();
          notifyListeners();
        });
  }

  // Ajouter un nouveau todo
  Future<void> addTodo(String title) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    if (title.trim().isEmpty) return;

    _setLoading(true);

    try {
      final now = DateTime.now();
      final todo = TodoItem(
        id: _firestore.collection('todos').doc().id,
        title: title.trim(),
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        userId: user.uid,
      );

      await _firestore.collection('todos').doc(todo.id).set(todo.toMap());
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'ajout du todo: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Mettre à jour un todo
  Future<void> updateTodo(String id, String newTitle) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    if (newTitle.trim().isEmpty) return;

    _setLoading(true);

    try {
      await _firestore.collection('todos').doc(id).update({
        'title': newTitle.trim(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour du todo: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Basculer l'état de complétion d'un todo
  Future<void> toggleTodoCompletion(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    _setLoading(true);

    try {
      final todo = _todos.firstWhere((todo) => todo.id == id);
      await _firestore.collection('todos').doc(id).update({
        'isCompleted': !todo.isCompleted,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du basculement du todo: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer un todo
  Future<void> deleteTodo(String id) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    _setLoading(true);

    try {
      await _firestore.collection('todos').doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression du todo: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer tous les todos de l'utilisateur
  Future<void> deleteAllTodos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    _setLoading(true);

    try {
      final batch = _firestore.batch();
      for (final todo in _todos) {
        batch.delete(_firestore.collection('todos').doc(todo.id));
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression de tous les todos: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Supprimer tous les todos complétés
  Future<void> deleteCompletedTodos() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    _setLoading(true);

    try {
      final batch = _firestore.batch();
      final completedTodos = _todos.where((todo) => todo.isCompleted);
      for (final todo in completedTodos) {
        batch.delete(_firestore.collection('todos').doc(todo.id));
      }
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression des todos complétés: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Obtenir les statistiques des todos
  Map<String, int> getTodoStats() {
    final total = _todos.length;
    final completed = _todos.where((todo) => todo.isCompleted).length;
    final pending = total - completed;

    return {'total': total, 'completed': completed, 'pending': pending};
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Nettoyer les données lors de la déconnexion
  void clearData() {
    _todos.clear();
    _isLoading = false;
    notifyListeners();
  }
}
