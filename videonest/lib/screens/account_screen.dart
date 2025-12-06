import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'add_video_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    setState(() {
      user = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Аккаунт")),
      body: Center(
        child: user == null
            ? const Text("Вы не вошли в аккаунт")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user?.photoURL ?? ""),
                    radius: 40,
                  ),
                  const SizedBox(height: 10),
                  Text("Привет, ${user?.displayName ?? 'Без имени'}"),
                  Text(user?.email ?? ""),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddVideoScreen(),
                        ),
                      );
                    },
                    label: const Text("Добавить видео"),
                  ),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    onPressed: signOut,
                    label: const Text("Выйти"),
                  ),
                ],
              ),
      ),
    );
  }
}
