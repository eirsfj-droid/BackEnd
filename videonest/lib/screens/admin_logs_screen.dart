import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLogsScreen extends StatelessWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Логи системы")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logs')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("Логи пока пустые"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final time = data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null;

              return ListTile(
                title: Text(data['action'] ?? ''),
                subtitle: Text('${data['details'] ?? ''}\nПользователь: ${data['email'] ?? 'unknown'}'),
                trailing: Text(time != null ? '${time.hour}:${time.minute}' : ''),
                isThreeLine: true,
              );
            },
          );
        },
      ),
    );
  }
}
