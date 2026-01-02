import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  void _showTaskDialog(BuildContext context, {DocumentSnapshot? taskToEdit}) {
    final titleController = TextEditingController(
      text: taskToEdit?['title'] ?? '',
    );
    final descController = TextEditingController(
      text: taskToEdit?['description'] ?? '',
    );

    DateTime selectedDate = taskToEdit != null
        ? (taskToEdit['deadline'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                taskToEdit == null ? 'Нова задача' : 'Редагувати задачу',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Назва'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Опис'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Дедлайн: ${selectedDate.toString().split(' ')[0]}",
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime(2101),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.deepPurple,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => selectedDate = picked);
                            }
                          },
                          child: const Text("Змінити"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Скасувати'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;

                    if (user != null && titleController.text.isNotEmpty) {
                      final taskData = {
                        'userId': user.uid,
                        'title': titleController.text,
                        'description': descController.text,
                        'deadline': Timestamp.fromDate(selectedDate),
                        if (taskToEdit == null) 'isDone': false,
                      };

                      // 1. Асинхронна операція (чекаємо запису в базу)
                      if (taskToEdit == null) {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .add(taskData);
                      } else {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(taskToEdit.id)
                            .update(taskData);
                      }

                      // 2. БЕЗПЕЧНА ПЕРЕВІРКА: чи екран ще існує після await?
                      // Це виправляє помилку "across async gaps"
                      if (!context.mounted) return;

                      // 3. Тепер безпечно закриваємо діалог
                      Navigator.pop(context);
                    }
                  },
                  child: Text(taskToEdit == null ? 'Додати' : 'Зберегти'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Мої Задачі")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 80,
                    // ВИПРАВЛЕНО: використання згідно з актуальними стандартами
                    color: Colors.deepPurple.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Задач немає. Додайте нову!",
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Логіка сортування перед рендерингом
          docs.sort((a, b) {
            bool doneA = a['isDone'] ?? false;
            bool doneB = b['isDone'] ?? false;
            if (doneA != doneB) return doneA ? 1 : -1;
            Timestamp t1 = a['deadline'];
            Timestamp t2 = b['deadline'];
            return t1.compareTo(t2);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final taskDoc = docs[index];
              final data = taskDoc.data() as Map<String, dynamic>;
              final deadlineDate = (data['deadline'] as Timestamp).toDate();
              final isDone = data['isDone'] ?? false;
              final now = DateTime.now();
              final daysLeft = deadlineDate.difference(now).inDays;
              final isOverdue =
                  !isDone && deadlineDate.isBefore(now) && daysLeft < 0;

              return Card(
                elevation: isDone ? 0 : 2,
                color: isDone ? Colors.grey[200] : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Checkbox(
                    value: isDone,
                    activeColor: Colors.deepPurple,
                    shape: const CircleBorder(),
                    onChanged: (bool? value) {
                      FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(taskDoc.id)
                          .update({'isDone': value});
                    },
                  ),
                  title: Text(
                    data['title'] ?? 'Без назви',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['description'] != null &&
                          data['description'].toString().isNotEmpty)
                        Text(
                          data['description'],
                          style: TextStyle(
                            color: isDone ? Colors.grey : Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDone
                              ? Colors.transparent
                              : (isOverdue
                                    ? Colors.red[50]
                                    : Colors.deepPurple[50]),
                          borderRadius: BorderRadius.circular(6),
                          border: isDone
                              ? Border.all(color: Colors.grey)
                              : null,
                        ),
                        child: Text(
                          "Дедлайн: ${deadlineDate.day}.${deadlineDate.month} ${isOverdue ? '! ПРОСТРОЧЕНО' : ''}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? Colors.grey
                                : (isOverdue ? Colors.red : Colors.deepPurple),
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Text("Редагувати"),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _showTaskDialog(context, taskToEdit: taskDoc),
                        ),
                      ),
                      PopupMenuItem(
                        child: const Text(
                          "Видалити",
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () => FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(taskDoc.id)
                            .delete(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
