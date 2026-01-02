class Task {
  final String title;
  final String description;
  final DateTime deadline;
  final bool isDone;

  Task({
    required this.title,
    required this.description,
    required this.deadline,
    this.isDone = false,
  });
}
