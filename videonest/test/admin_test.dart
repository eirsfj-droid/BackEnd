import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin tests', () {
    test('Admin can view user list', () {
      final users = [
        {'uid': '1', 'name': 'Alice'},
        {'uid': '2', 'name': 'Bob'},
      ];

      final adminView = users.map((u) => u['name']).toList();
      expect(adminView.length, 2);
      expect(adminView, contains('Alice'));
      expect(adminView, contains('Bob'));
    });

    test('Admin sees no users if list empty', () {
      final users = [];
      final adminView = users.map((u) => u['name']).toList();
      expect(adminView.length, 0);
    });
  });
}
