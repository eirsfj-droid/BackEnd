// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName ?? '';
  }

  // ● Выбор изображения
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  // ● Загрузка аватара
  Future<String?> _uploadAvatar(File file) async {
    try {
      final ref =
          FirebaseStorage.instance.ref().child('avatars/${widget.user.uid}.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Avatar upload error: $e");
      return null;
    }
  }

  // ● Изменение имени
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

  // ● Изменение фото
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Аватар обновлён")),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ● Выйти
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
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
      ),

      // ● Главная колонка
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ● Аватар
            GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: CircleAvatar(
                radius: 55,
                backgroundImage: avatarProvider,
                child: avatarProvider == null
                    ? const Icon(Icons.person, size: 55)
                    : null,
              ),
            ),

            const SizedBox(height: 12),

            // ● Email или "Гость"
            Text(
              isGuest ? "Гость" : (user.email ?? "Без email"),
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 25),

            // ● Поле Имя
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Ваше имя",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // ● Кнопки сохранить имя + загрузить фото
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updateName,
                  icon: const Icon(Icons.save),
                  label: const Text("Сохранить имя"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updateAvatar,
                  icon: const Icon(Icons.image),
                  label: const Text("Обновить фото"),
                ),
              ],
            ),

            const SizedBox(height: 25),

            // ● Выход
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Выйти"),
              onPressed: _isSaving ? null : _signOut,
            ),
          ],
        ),
      ),
    );
  }
}
