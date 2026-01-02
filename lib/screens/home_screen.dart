import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/menu_card.dart';
import 'health_screen.dart';
import 'student_screen.dart';
import 'tasks_screen.dart';
import 'login_screen.dart';
import 'focus_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // Отримуємо ім'я користувача для привітання
    final String userName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'Студенте';

    return Scaffold(
      appBar: AppBar(
        title: const Text('MIST Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Text(
              'Привіт, $userName! 👋',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.deepPurple.withValues(alpha: 0.1),
                ),
              ),
              child: const Text(
                'Ласкаво просимо до MIST Portal — твого персонального помічника у навчанні. '
                'Редагуй профіль, керуй завданнями, слідкуй за здоров’ям та фокусуйся на важливому в одному місці.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 25),
            Text(
              'Твоя робоча область:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 15),

            // Набір кнопок, що ведуть до інших екранів
            const MenuCard(
              icon: Icons.timer_outlined,
              label: 'Режим Фокусу (Pomodoro)',
              color: Colors.orange,
              page: FocusScreen(),
            ),

            const MenuCard(
              icon: Icons.favorite_rounded,
              label: 'Здоров\'я та Звички',
              color: Colors.blue,
              page: HealthScreen(),
            ),

            const MenuCard(
              icon: Icons.badge_outlined,
              label: 'Профіль Студента',
              color: Colors.deepPurple,
              page: StudentScreen(),
            ),

            const MenuCard(
              icon: Icons.task_alt_rounded,
              label: 'Менеджер Задач',
              color: Colors.green,
              page: TasksScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
