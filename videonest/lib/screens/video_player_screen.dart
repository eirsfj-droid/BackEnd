// lib/screens/video_player_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String? videoId;
  final String? uploadedById;
  final String? uploadedByName;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    this.videoId,
    this.uploadedById,
    this.uploadedByName,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _showControls = false;
  Timer? _controlsTimer;
  TextEditingController _commentController = TextEditingController();

  // Видео данные
  String _videoTitle = 'Загрузка...';
  String _videoId = '';
  String _uploadedByName = 'Аноним';
  int _likesCount = 0;
  int _dislikesCount = 0;
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSubscribed = false;
  IconData _bellIcon = Icons.notifications_none;
  String? _publishDate;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _loadVideoData();
  }

  Future<void> _loadVideoData() async {
    try {
      String videoId = widget.videoId ?? '';
      DocumentSnapshot doc;

      if (videoId.isNotEmpty) {
        doc = await FirebaseFirestore.instance
            .collection('videos')
            .doc(videoId)
            .get();
      } else {
        final query = await FirebaseFirestore.instance
            .collection('videos')
            .where('videoUrl', isEqualTo: widget.videoUrl)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
          videoId = doc.id;
        } else {
          return;
        }
      }

      final data = doc.data() as Map<String, dynamic>?;

      if (data != null) {
        final timestamp = data['createdAt'];
        setState(() {
          _videoId = videoId;
          _videoTitle = data['title'] ?? 'Видео';
          _uploadedByName = widget.uploadedByName ?? data['uploadedByName'] ?? 'Аноним';
          _likesCount = data['likes'] ?? 0;
          _dislikesCount = data['dislikes'] ?? 0;

          if (timestamp != null) {
            final date = (timestamp as Timestamp).toDate();
            _publishDate = DateFormat('d MMMM yyyy', 'ru').format(date);
          }
        });
      }
    } catch (e) {
      print("Ошибка загрузки данных видео: $e");
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    _controlsTimer?.cancel();
    if (_showControls) {
      _controlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showControls = false);
      });
    }
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) _isDisliked = false;
      _likesCount += _isLiked ? 1 : -1;
      if (_isDisliked) _dislikesCount = 0;
    });
  }

  void _handleDislike() {
    setState(() {
      _isDisliked = !_isDisliked;
      if (_isDisliked) _isLiked = false;
      _dislikesCount += _isDisliked ? 1 : -1;
      if (_isLiked) _likesCount = 0;
    });
  }

  void _handleSubscribe() {
    setState(() {
      _isSubscribed = !_isSubscribed;
      _bellIcon =
          _isSubscribed ? Icons.notifications_active : Icons.notifications_none;
    });
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('videos')
          .doc(_videoId)
          .collection('comments')
          .add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (_) {}
  }

  Widget _buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .doc(_videoId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Комментариев пока нет'),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final date = data['timestamp'] != null
                ? DateFormat('dd.MM.yyyy HH:mm')
                    .format((data['timestamp'] as Timestamp).toDate())
                : '';
            return ListTile(
              leading: const Icon(Icons.comment, color: Colors.redAccent),
              title: Text(data['text'] ?? ''),
              subtitle: Text(date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            );
          },
        );
      },
    );
  }

  Widget _buildRecommendedVideos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('videos')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final videos = snapshot.data!.docs
            .where((doc) => doc['videoUrl'] != widget.videoUrl)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Рекомендованные видео",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              itemCount: videos.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final video = videos[index].data() as Map<String, dynamic>;
                final String title = video['title'] ?? 'Нет названия';
                final String? videoUrl = video['videoUrl'];
                final String? thumbnailUrl = video['thumbnailUrl'];
                final String? uploadedByName = video['uploadedByName'];

                return GestureDetector(
                  onTap: () {
                    if (videoUrl != null && videoUrl.isNotEmpty) {
                      Navigator.pushReplacement(
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
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: double.infinity,
                              height: 120,
                              color: Colors.grey[300],
                              child:
                                  const Icon(Icons.videocam, size: 50),
                            ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[400],
                              child: const Icon(Icons.person,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    uploadedByName ?? "Аноним",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
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
            ),
          ],
        );
      },
    );
  }

  void _toggleFullScreen() {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _controlsTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _controller.value.isInitialized
        ? _controller.value.position.inMilliseconds /
            _controller.value.duration.inMilliseconds
        : 0.0;

    return Scaffold(
      body: ListView(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              children: [
                // Видео фиксированного размера
                Container(
                  height: 260,
                  color: Colors.black,
                  width: double.infinity,
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
                if (_showControls && _controller.value.isInitialized)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _controller.value.isPlaying
                                    ? _controller.pause()
                                    : _controller.play();
                              });
                            },
                          ),
                          Expanded(
                            child: Slider(
                              activeColor: Colors.red,
                              value: progress.clamp(0.0, 1.0),
                              onChanged: (v) {
                                final newPos = Duration(
                                  milliseconds: (v *
                                          _controller
                                              .value.duration.inMilliseconds)
                                      .toInt(),
                                );
                                _controller.seekTo(newPos);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.fullscreen,
                                color: Colors.white),
                            onPressed: _toggleFullScreen,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Информация о видео
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _videoTitle,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Автор и подписка
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const CircleAvatar(radius: 18, child: Icon(Icons.person)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_uploadedByName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                TextButton(
                  onPressed: _handleSubscribe,
                  child: Text(
                    _isSubscribed ? 'ПОДПИСАН' : 'ПОДПИСАТЬСЯ',
                    style: TextStyle(
                        color: _isSubscribed ? Colors.grey : Colors.red,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isSubscribed)
                  Icon(_bellIcon, color: Colors.red),
              ],
            ),
          ),
          // Лайки, Дизлайки, Шаринг, Дата
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: _isLiked ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _handleLike,
                ),
                Text('$_likesCount'),
                IconButton(
                  icon: Icon(
                    _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                    color: _isDisliked ? Colors.red : Colors.grey,
                  ),
                  onPressed: _handleDislike,
                ),
                Text('$_dislikesCount'),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.grey),
                  onPressed: () {
                    Share.share(
                      'Посмотрите видео "$_videoTitle" от $_uploadedByName по ссылке: ${widget.videoUrl}',
                      subject: 'Видео из VideoNest',
                    );
                  },
                ),
                const Spacer(),
                if (_publishDate != null)
                  Text(
                    _publishDate!,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Комментарии
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Написать комментарий...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.all(8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _postComment,
                )
              ],
            ),
          ),
          _buildComments(),
          // Рекомендованные видео
          _buildRecommendedVideos(),
        ],
      ),
    );
  }
}
