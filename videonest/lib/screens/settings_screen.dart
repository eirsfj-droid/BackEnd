import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <- важно
import 'AdminPanelScreen.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  final VoidCallback onSignOut;

  const SettingsScreen({
    Key? key,
    required this.user,
    required this.onSignOut,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSaving = false;
  File? _imageFile;
  bool isAdmin = false;
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // <- для разлогина

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final tokenResult = await user.getIdTokenResult(true);
      setState(() {
        isAdmin = tokenResult.claims?['admin'] == true;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadAvatar(File file) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('avatars/${widget.user.uid}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Avatar upload error: $e");
      return null;
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await widget.user.updateDisplayName(newName);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set({'name': newName}, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Имя обновлено")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateAvatar() async {
    if (_imageFile == null) return;
    setState(() => _isSaving = true);
    try {
      final url = await _uploadAvatar(_imageFile!);
      if (url != null) {
        await widget.user.updatePhotoURL(url);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .set({'avatar': url}, SetOptions(merge: true));
        setState(() => _imageFile = null);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Аватар обновлён")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // <- Обновленный выход
  Future<void> _signOut() async {
    try {
      // Разлогиниваем Google, если использовался
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint("Google SignOut error: $e");
    }

    await FirebaseAuth.instance.signOut(); // Firebase
    widget.onSignOut();
  }

  bool get isGuest =>
      FirebaseAuth.instance.currentUser != null &&
      FirebaseAuth.instance.currentUser!.isAnonymous;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser ?? widget.user;
    final ImageProvider? avatarProvider = _imageFile != null
        ? FileImage(_imageFile!)
        : (user.photoURL != null ? NetworkImage(user.photoURL!) : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройки"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? const Icon(Icons.person, size: 60, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isGuest ? "Гость" : (user.email ?? "Без email"),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 25),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Ваше имя",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white10,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _updateName,
                    icon: const Icon(Icons.save),
                    label: const Text("Сохранить имя"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _updateAvatar,
                    icon: const Icon(Icons.image),
                    label: const Text("Обновить фото"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            if (isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text("Админ-панель"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminPanelScreen()),
                  );
                },
              ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Выйти"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }
} 