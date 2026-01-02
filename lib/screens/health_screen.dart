import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final TextEditingController _waterController = TextEditingController();
  bool _habitEyeExercise = false;
  bool _habitStretch = false;
  bool _habitWalk = false;

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не вдалося відкрити: $urlString')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Помилка: $e')));
      }
    }
  }

  Future<void> _seedDatabase() async {
    final collection = FirebaseFirestore.instance.collection('health_tips');
    final snapshot = await collection.get();

    // Безпечна перевірка після await
    if (!mounted) return;

    if (snapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Статті вже завантажені!')));
      return;
    }

    final List<Map<String, String>> tips = [
      {
        'title': 'Чому вода важлива?',
        'description': 'Вода впливає на енергію та мозок.',
        'icon': 'water',
        'url':
            'https://www.healthline.com/nutrition/7-health-benefits-of-water',
      },
      {
        'title': 'Правило 20-20-20',
        'description': 'Збереження зору при роботі за ПК.',
        'icon': 'eye',
        'url': 'https://www.aao.org/eye-health/tips-prevention/computer-usage',
      },
      {
        'title': 'Ергономіка сидіння',
        'description': 'Як сидіти без болю в спині.',
        'icon': 'back',
        'url':
            'https://www.mayoclinic.org/healthy-lifestyle/adult-health/in-depth/office-ergonomics/art-20046169',
      },
      {
        'title': 'Користь ходьби',
        'description': 'Як 30 хвилин ходьби змінюють здоров\'я.',
        'icon': 'walk',
        'url':
            'https://www.betterhealth.vic.gov.au/health/healthyliving/walking-for-good-health',
      },
    ];

    for (var tip in tips) {
      await collection.add(tip);
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Базу оновлено!')));
    }
  }

  Future<void> _addWaterRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (_waterController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('health_logs').add({
        'userId': user.uid,
        'type': 'water',
        'amount': int.tryParse(_waterController.text) ?? 0,
        'date': Timestamp.now(),
      });

      _waterController.clear();

      // Безпечна перевірка після await
      if (!mounted) return;

      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Вода додана! 💧')));
    }
  }

  IconData _getIconForName(String iconName) {
    switch (iconName) {
      case 'eye':
        return Icons.visibility_outlined;
      case 'back':
        return Icons.chair_outlined;
      case 'walk':
        return Icons.directions_walk;
      case 'water':
        return Icons.water_drop_outlined;
      default:
        return Icons.lightbulb_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Здоров\'я та Звички'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _seedDatabase,
            tooltip: 'Завантажити статті',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.water_drop, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        "Гідратація",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _waterController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.2),
                            hintText: '250',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            suffixText: 'мл',
                            suffixStyle: const TextStyle(color: Colors.white),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      FloatingActionButton.small(
                        onPressed: _addWaterRecord,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Щоденні звички ✅',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _buildHabitTile(
                    'Вправи для очей (2 хв)',
                    _habitEyeExercise,
                    (v) => setState(() => _habitEyeExercise = v!),
                  ),
                  const Divider(height: 1),
                  _buildHabitTile(
                    'Розминка спини',
                    _habitStretch,
                    (v) => setState(() => _habitStretch = v!),
                  ),
                  const Divider(height: 1),
                  _buildHabitTile(
                    'Прогулянка (5000 кроків)',
                    _habitWalk,
                    (v) => setState(() => _habitWalk = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'База знань 📚',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('health_tips')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tips = snapshot.data!.docs;
                if (tips.isEmpty) {
                  return const Text(
                    "Натисніть кнопку зверху, щоб завантажити статті.",
                  );
                }

                return Column(
                  children: tips.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple.withValues(
                            alpha: 0.1,
                          ),
                          child: Icon(
                            _getIconForName(data['icon'] ?? ''),
                            color: Colors.deepPurple,
                          ),
                        ),
                        title: Text(
                          data['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          if (data['url'] != null) {
                            _launchURL(data['url']);
                          }
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text(
              'Історія води 🕒',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('health_logs')
                  .where('userId', isEqualTo: user?.uid)
                  .orderBy('date', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox();
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text('Поки що записів немає');
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            "${data['amount']} мл",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitTile(String title, bool value, Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(
        title,
        style: TextStyle(
          decoration: value ? TextDecoration.lineThrough : null,
          color: value ? Colors.grey : Colors.black87,
        ),
      ),
      value: value,
      activeColor: Colors.blue,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
