import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User tests', () {
    test('Admin can view users', () {
      final users = [
        {'uid': '1', 'name': 'Alice'},
        {'uid': '2', 'name': 'Bob'},
      ];

      final adminView = users.map((u) => u['name']).toList();

      expect(adminView.length, 2);
      expect(adminView, contains('Alice'));
    });

    test('Anonymous user check', () {
      final user = {'isAnonymous': true};
      expect(user['isAnonymous'], true);
    });
  });
}
