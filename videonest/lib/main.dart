import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';   // ⭐ новый импорт

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoNest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.red,
        brightness: Brightness.dark,
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  User? user;

  // ⭐ Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Ошибка входа через Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка входа через Google")),
      );
      return null;
    }
  }

  // ⭐ Гостевой вход
  Future<UserCredential?> signInAnonymously() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      return result;
    } catch (e) {
      debugPrint("Ошибка гостевого входа: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка гостевого входа")),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.redAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Добро пожаловать в VideoNest",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                ElevatedButton.icon(
                  icon: const Icon(Icons.login, color: Colors.white),
                  label: const Text("Войти через Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final result = await signInWithGoogle();
                    if (result != null) setState(() => user = result.user);
                  },
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline),
                  label: const Text("Продолжить как гость"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final result = await signInAnonymously();
                    if (result != null) setState(() => user = result.user);
                  },
                ),

                const SizedBox(height: 60),
                const Text(
                  "Войдите чтобы загружать видео\nили смотрите как гость",
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MainScreen(
      user: user!,
      onSignOut: () => setState(() => user = null),
    );
  }
}

//
// ⭐⭐ ОБНОВЛЁННЫЕ НИЖНИЙ БАР + СТРАНИЦЫ ⭐⭐
//   Главная | Вы | Настройки
//

class MainScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSignOut;

  const MainScreen({super.key, required this.user, required this.onSignOut});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      ProfileScreen(user: widget.user, onSignOut: widget.onSignOut),
      SettingsScreen(user: widget.user, onSignOut: widget.onSignOut),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: Colors.redAccent.withOpacity(0.3),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: "Главная"),
          NavigationDestination(icon: Icon(Icons.person), label: "Вы"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Настройки"),
        ],
      ),
    );
  }
}
