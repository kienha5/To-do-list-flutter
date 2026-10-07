import '../models/todo.dart';

enum TodoFilter { all, today, upcoming }

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatDue(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

List<Todo> applyFilter(List<Todo> todos, TodoFilter filter, String query) {
  final now = DateTime.now();
  final q = query.trim().toLowerCase();

  final result = todos.where((t) {
    final matchQuery = q.isEmpty || t.title.toLowerCase().contains(q);
    final d = t.dueAt;
    final matchFilter = switch (filter) {
      TodoFilter.all => true,
      TodoFilter.today => d != null && isSameDay(d, now),
      TodoFilter.upcoming => d != null && d.isAfter(now) && !isSameDay(d, now),
    };
    return matchQuery && matchFilter;
  }).toList();

  result.sort((a, b) =>
      (a.dueAt ?? DateTime(9999)).compareTo(b.dueAt ?? DateTime(9999)));
  return result;
}