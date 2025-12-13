import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'Все видео'; // или 'Мои видео'
  String _searchQuery = '';

  User? get currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // 🔹 Получаем все видео из Firestore
    final videosQuery = FirebaseFirestore.instance
        .collection('videos')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
      ),
      body: Column(
        children: [
          // 🔹 Поле поиска + фильтр
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Поиск видео',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(
                      value: 'Все видео',
                      child: Text('Все видео'),
                    ),
                    DropdownMenuItem(
                      value: 'Мои видео',
                      child: Text('Мои видео'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _filter = val!;
                    });
                  },
                ),
              ],
            ),
          ),
          // 🔹 Список видео
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: videosQuery.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Ошибка загрузки видео"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Видео пока нет"));
                }

                // 🔹 Локальная фильтрация с учетом поиска и фильтра “Мои видео”
                final allDocs = snapshot.data!.docs;
                final docs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();

                  // Фильтр “Мои видео”
                  if (_filter == 'Мои видео' && currentUser != null) {
                    if (data['userId'] != currentUser!.uid) return false;
                  }

                  // Поиск по названию
                  if (_searchQuery.isNotEmpty) {
                    return title.contains(_searchQuery);
                  }

                  return true;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Видео не найдено"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String title = data['title'] ?? 'Нет названия';
                    final String description = data['description'] ?? '';
                    final String? videoUrl = data['videoUrl'];
                    final String? thumbnailUrl = data['thumbnailUrl'];
                    final String? uploadedByName = data['uploadedByName'];

                    return GestureDetector(
                      onTap: () {
                        if (videoUrl != null && videoUrl.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  VideoPlayerScreen(videoUrl: videoUrl),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          thumbnailUrl != null && thumbnailUrl.isNotEmpty
                              ? Image.network(
                                  thumbnailUrl,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.videocam, size: 50),
                                ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey[400],
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        description,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        uploadedByName ?? "Аноним",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
