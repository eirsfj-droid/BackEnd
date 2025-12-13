import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Video data tests', () {
    test('Video has required fields', () {
      final video = {
        'title': 'Demo Video',
        'description': 'This is a demo video',
        'videoUrl': 'https://example.com/video.mp4',
        'uploadedBy': 'user123',
      };

      expect(video['title'], isNotEmpty);
      expect(video['videoUrl'], contains('http'));
      expect(video['uploadedBy'], isNotEmpty);
    });

    test('Video description can be empty', () {
      final video = {'title': 'Test', 'description': '', 'videoUrl': 'https://example.com'};
      expect(video['description']?.isEmpty, true);
    });
  });
}
