// lib/screens/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference logsCollection =
      FirebaseFirestore.instance.collection('logs');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Админ-панель"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Пользователи",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: usersCollection.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final users = snapshot.data!.docs;
                  if (users.isEmpty) {
                    return const Center(child: Text("Пользователи не найдены"));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final userData = user.data() as Map<String, dynamic>;

                      // Берем email только из Firestore
                      final email = userData['email'] ?? "Без email";
                      final name = (userData['name'] != null &&
                              userData['name'].toString().isNotEmpty)
                          ? userData['name']
                          : email; // если имени нет, берем email
                      final isAdmin = userData['admin'] ?? false;

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(email),
                        trailing: Switch(
                          activeColor: Colors.redAccent,
                          value: isAdmin,
                          onChanged: (val) async {
                            try {
                              // Обновляем роль пользователя
                              await usersCollection.doc(user.id).update({
                                'admin': val,
                              });

                              // Создаем лог
                              await logsCollection.add({
                                'userName': name,
                                'action':
                                    val ? 'Назначен админ' : 'Снят админ',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                    "$name теперь ${val ? 'админ' : 'пользователь'}"),
                              ));
                            } catch (e) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Ошибка: $e"),
                              ));
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "Логи действий",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream: logsCollection
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final logs = snapshot.data!.docs;
                  if (logs.isEmpty) {
                    return const Center(child: Text("Логи пусты"));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final logData =
                          logs[index].data() as Map<String, dynamic>;
                      final userName = logData['userName'] ?? "Аноним";
                      final action = logData['action'] ?? "Нет действия";
                      final timestamp = logData['createdAt'] != null
                          ? (logData['createdAt'] as Timestamp).toDate()
                          : DateTime.now();

                      return ListTile(
                        leading:
                            const Icon(Icons.history, color: Colors.redAccent),
                        title: Text(action),
                        subtitle: Text("$userName • ${timestamp.toLocal()}"),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
