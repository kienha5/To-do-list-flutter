class Todo {
  final int id;
  final String title;
  final DateTime? dueAt;

  const Todo({required this.id, required this.title, this.dueAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueAt': dueAt?.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'] as int,
        title: json['title'] as String,
        dueAt: json['dueAt'] == null
            ? null
            : DateTime.parse(json['dueAt'] as String),
      );
}