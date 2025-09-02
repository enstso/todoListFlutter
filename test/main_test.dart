import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/main.dart';

void main() {
  group('TodoList Tests', () {
    late TodoList todoList;

    setUp(() {
      todoList = TodoList();
    });

    test('should start with empty todos', () {
      expect(todoList.todos, isEmpty);
    });

    test('should add todo correctly', () {
      todoList.addTodo('Test todo');
      expect(todoList.todos.length, 1);
      expect(todoList.todos.first, 'Test todo');
    });

    test('should not add empty todo', () {
      todoList.addTodo('');
      todoList.addTodo('   ');
      expect(todoList.todos, isEmpty);
    });

    test('should trim whitespace from todos', () {
      todoList.addTodo('  Test todo  ');
      expect(todoList.todos.first, 'Test todo');
    });

    test('should remove todo correctly', () {
      todoList.addTodo('Todo 1');
      todoList.addTodo('Todo 2');
      todoList.removeTodo(0);
      expect(todoList.todos.length, 1);
      expect(todoList.todos.first, 'Todo 2');
    });

    test('should not remove todo with invalid index', () {
      todoList.addTodo('Todo 1');
      todoList.removeTodo(-1);
      todoList.removeTodo(5);
      expect(todoList.todos.length, 1);
    });

    test('should update todo correctly', () {
      todoList.addTodo('Original todo');
      todoList.updateTodo(0, 'Updated todo');
      expect(todoList.todos.first, 'Updated todo');
    });

    test('should not update todo with invalid index', () {
      todoList.addTodo('Todo 1');
      todoList.updateTodo(-1, 'Invalid');
      todoList.updateTodo(5, 'Invalid');
      expect(todoList.todos.first, 'Todo 1');
    });

    test('should not update todo with empty text', () {
      todoList.addTodo('Original todo');
      todoList.updateTodo(0, '');
      todoList.updateTodo(0, '   ');
      expect(todoList.todos.first, 'Original todo');
    });

    test('should clear all todos', () {
      todoList.addTodo('Todo 1');
      todoList.addTodo('Todo 2');
      todoList.clearAllTodos();
      expect(todoList.todos, isEmpty);
    });

    test('should return unmodifiable list', () {
      todoList.addTodo('Todo 1');
      expect(
        () => todoList.todos.add('Todo 2'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
