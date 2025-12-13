import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Logger {
  static Future<void> log(String action, {User? user, String? details}) async {
    final uid = user?.uid ?? 'unknown';
    final email = user?.email ?? 'anonymous';
    await FirebaseFirestore.instance.collection('logs').add({
      'uid': uid,
      'email': email,
      'action': action,
      'details': details ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
