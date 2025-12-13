import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic VideoNest tests', () {
    test('Update user name', () {
      String name = 'OldName';
      name = 'NewName';
      expect(name, 'NewName');
    });

    test('Check video data', () {
      final video = {
        'title': 'Demo Video',
        'description': 'Just a demo',
        'videoUrl': 'https://example.com/video.mp4',
      };

      expect(video['title'], isNotEmpty);
      expect(video['videoUrl'], contains('http'));
    });
  });
}
