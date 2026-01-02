import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../data/student.dart';
import '../services/storage_service.dart';

class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final StorageService _storageService = StorageService();
  bool _isUploading = false;

  // Створення дефолтного профілю для нових користувачів
  Future<void> _createDefaultProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'firstName': "Ім'я",
      'lastName': "Прізвище",
      'group': "Група",
      'specialty': "Спеціальність",
      'studentId': "000000",
      'phone': "+380...",
      'email': user.email,
      'bio': "Напишіть щось про себе...",
      'photoUrl': "",
    });
  }

  Future<void> _changePhoto(BuildContext context, ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final XFile? pickedFile = await _storageService.pickImage(source);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final File imageFile = File(pickedFile.path);
      final String? downloadUrl = await _storageService.uploadUserAvatar(
        user.uid,
        imageFile,
      );

      if (downloadUrl != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'photoUrl': downloadUrl});
      }
    } catch (e) {
      // Перевірка mounted перед показом SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Потрібен тариф Blaze для Storage.')),
        );
      }
    } finally {
      // ПЕРЕВІРКА mounted перед зміною стану та навігацією
      if (mounted) {
        setState(() => _isUploading = false);
        Navigator.pop(context);
      }
    }
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Вибрати з галереї'),
              onTap: () => _changePhoto(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Зробити фото'),
              onTap: () => _changePhoto(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Student student) {
    final nameController = TextEditingController(text: student.firstName);
    final surnameController = TextEditingController(text: student.lastName);
    final groupController = TextEditingController(text: student.group);
    final specialtyController = TextEditingController(text: student.specialty);
    final idController = TextEditingController(text: student.studentId);
    final phoneController = TextEditingController(text: student.phone);
    final bioController = TextEditingController(text: student.bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редагувати профіль'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, "Ім'я"),
              _buildTextField(surnameController, "Прізвище"),
              _buildTextField(groupController, "Група"),
              _buildTextField(specialtyController, "Спеціальність"),
              _buildTextField(idController, "№ Студентського"),
              _buildTextField(phoneController, "Телефон", isPhone: true),
              _buildTextField(bioController, "Про себе", maxLines: 3),
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
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({
                      'firstName': nameController.text,
                      'lastName': surnameController.text,
                      'group': groupController.text,
                      'specialty': specialtyController.text,
                      'studentId': idController.text,
                      'phone': phoneController.text,
                      'bio': bioController.text,
                    });

                // Перевірка mounted перед Navigator.pop
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Зберегти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Мій Профіль"),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData &&
                  snapshot.data != null &&
                  snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () =>
                      _showEditDialog(context, Student.fromMap(data)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Обробка випадку, коли документа ще не існує
          if (!snapshot.hasData ||
              snapshot.data == null ||
              !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Профіль ще не створено"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createDefaultProfile,
                    child: const Text("Створити профіль"),
                  ),
                ],
              ),
            );
          }

          final rawData = snapshot.data!.data() as Map<String, dynamic>;
          final student = Student.fromMap(rawData);
          final String? photoUrl = rawData['photoUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoOptions(context),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.deepPurple[50],
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : const AssetImage("assets/photo.jpg")
                                        as ImageProvider,
                            ),
                            if (_isUploading) const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "${student.firstName} ${student.lastName}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${student.specialty} • ${student.group}",
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      _buildInfoRow(
                        Icons.badge_outlined,
                        "ID Студента",
                        student.studentId,
                      ),
                      _buildInfoRow(
                        Icons.phone_outlined,
                        "Телефон",
                        student.phone,
                      ),
                      _buildInfoRow(
                        Icons.email_outlined,
                        "Email",
                        student.email,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Про себе",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        student.bio,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
