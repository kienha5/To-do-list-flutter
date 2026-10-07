import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoStorage {
  static const _key = 'todos';

  Future<List<Todo>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => Todo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> save(List<Todo> todos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(todos.map((t) => t.toJson()).toList()),
    );
  }
}