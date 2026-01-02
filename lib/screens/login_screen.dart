import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  // Контролери для полів вводу
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLogin = true; // Перемикач: Вхід чи Реєстрація
  String? errorMessage;

  // Функція обробки натискання кнопки
  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    User? user;
    if (isLogin) {
      user = await _authService.signIn(email, password);
    } else {
      user = await _authService.signUp(email, password);
    }

    if (user != null) {
      // Якщо успішно -> переходимо на Головну
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        errorMessage = "Помилка! Перевірте дані або спробуйте інший email.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              Text(
                isLogin ? "Вхід в систему" : "Реєстрація",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Поле Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // Поле Пароль
              TextField(
                controller: _passwordController,
                obscureText: true, // Приховати текст
                decoration: const InputDecoration(
                  labelText: "Пароль",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              // Повідомлення про помилку
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 25),

              // Кнопка Дії
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: Text(
                    isLogin ? "Увійти" : "Зареєструватися",
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),

              // Перемикач режимів
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin; // Змінюємо режим
                    errorMessage = null;
                  });
                },
                child: Text(
                  isLogin
                      ? "Немає акаунту? Зареєструватися"
                      : "Вже є акаунт? Увійти",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
