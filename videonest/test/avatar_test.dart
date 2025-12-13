import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Avatar tests', () {
    test('User has avatar URL', () {
      final user = {'avatarUrl': 'https://example.com/avatar.jpg'};
      expect(user['avatarUrl'], isNotEmpty);
      expect(user['avatarUrl'], contains('http'));
    });

    test('Avatar can be empty', () {
      final user = {'avatarUrl': ''};
      expect(user['avatarUrl']?.isEmpty, true);
    });
  });
}
