import 'package:flutter/material.dart';
import '../logic/todo_filter.dart';
import '../models/todo.dart';
import '../services/notification_service.dart';
import '../services/todo_storage.dart';
import 'add_todo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storage = TodoStorage();
  List<Todo> _todos = [];
  final Set<int> _selected = {}; // id các ghi chú đang được tick
  TodoFilter _filter = TodoFilter.all;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final todos = await _storage.load();
    setState(() {
      _todos = todos;
      _loading = false;
    });
  }

  Future<void> _addTodo() async {
    final todo = await Navigator.push<Todo>(
      context,
      MaterialPageRoute(builder: (_) => const AddTodoScreen()),
    );
    if (todo == null) return;
    setState(() => _todos.add(todo));
    await _storage.save(_todos);
    await NotificationService.instance.scheduleReminder(todo);
  }

  void _toggleSelected(int id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa ghi chú'),
        content: Text('Bạn có chắc muốn xóa $count ghi chú đã chọn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return; // Hủy: quay lại, giữ nguyên các ô đã tick

    final ids = Set<int>.of(_selected);
    setState(() {
      _todos.removeWhere((t) => ids.contains(t.id));
      _selected.clear();
    });
    await _storage.save(_todos);
    for (final id in ids) {
      await NotificationService.instance.cancel(id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xóa $count ghi chú')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = applyFilter(_todos, _filter, _query);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ghi chú')),
      floatingActionButton: _selected.isEmpty
          ? FloatingActionButton(
              onPressed: _addTodo,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FilledButton.icon(
                  onPressed: _deleteSelected,
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                  ),
                  icon: const Icon(Icons.delete),
                  label: Text('Xóa ${_selected.length} ghi chú'),
                ),
              ),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Tìm kiếm ghi chú',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SegmentedButton<TodoFilter>(
                  segments: const [
                    ButtonSegment(value: TodoFilter.all, label: Text('All')),
                    ButtonSegment(value: TodoFilter.today, label: Text('Today')),
                    ButtonSegment(
                        value: TodoFilter.upcoming, label: Text('Upcoming')),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: visible.isEmpty
                      ? const Center(child: Text('Không có ghi chú nào'))
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final t = visible[i];
                            final due = t.dueAt;
                            final overdue =
                                due != null && due.isBefore(DateTime.now());
                            return ListTile(
                              key: ValueKey(t.id),
                              leading: Checkbox(
                                value: _selected.contains(t.id),
                                onChanged: (_) => _toggleSelected(t.id),
                              ),
                              title: Text(t.title),
                              subtitle: due == null
                                  ? null
                                  : Text(
                                      formatDue(due),
                                      style: TextStyle(
                                          color: overdue ? Colors.red : null),
                                    ),
                              onTap: () => _toggleSelected(t.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}