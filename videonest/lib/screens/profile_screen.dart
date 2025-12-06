import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_video_screen.dart';

/// Экран "Вы" — личный профиль, аватар, загрузка видео, выход
class ProfileScreen extends StatelessWidget {
  final User user;
  final VoidCallback onSignOut;

  const ProfileScreen({super.key, required this.user, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final bool isGuest = user.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ваш профиль"),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Аватар ---
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.redAccent,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // --- Имя пользователя или Гость ---
          Center(
            child: Text(
              isGuest ? "Гость" : (user.displayName ?? "Пользователь"),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 30),

          // --- Кнопка добавления видео ---
          if (!isGuest)
            ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("Загрузить новое видео"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddVideoScreen()),
                );
              },
            ),

          if (!isGuest) const SizedBox(height: 20),

          // --- Выход ---
          ElevatedButton.icon(
            icon: const Icon(Icons.exit_to_app),
            label: Text(isGuest ? "Выйти из гостевого режима" : "Выйти из аккаунта"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[850],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              onSignOut();
            },
          ),
        ],
      ),
    );
  }
}
