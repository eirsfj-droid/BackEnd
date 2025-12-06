import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/video_service.dart';

class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({Key? key}) : super(key: key);

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final VideoService _videoService = VideoService();

  File? _pickedVideo;
  File? _pickedThumbnail;
  bool _isUploading = false;
  double _progress = 0.0;

  Future<void> _pickVideo() async {
    final file = await _videoService.pickVideoFromGallery();
    if (file != null) {
      setState(() => _pickedVideo = file);
    }
  }

  Future<void> _pickThumbnail() async {
    final file = await _videoService.pickThumbnailFromGallery();
    if (file != null) {
      setState(() => _pickedThumbnail = file);
    }
  }

  Future<void> _upload() async {
    final user = FirebaseAuth.instance.currentUser;
    if (_pickedVideo == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Сначала выберите видео')));
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Введите название')));
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    try {
      final result = await _videoService.uploadVideoWithThumbnail(
        videoFile: _pickedVideo!,
        providedThumbnailFile: _pickedThumbnail,
        userId: user?.uid,
        onVideoProgress: (p) {
          setState(() => _progress = p);
        },
      );

      
      await FirebaseFirestore.instance.collection('videos').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'videoUrl': result.video.downloadUrl,
        'storagePath': result.video.storagePath,
        'thumbnailUrl': result.thumbnail?.downloadUrl,
        'thumbnailStoragePath': result.thumbnail?.storagePath,
        'uploadedBy': user?.uid, 
        'uploadedByName': user?.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Видео загружено')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Ошибка загрузки: $e')));
    } finally {
      setState(() {
        _isUploading = false;
        _progress = 0.0;
        _pickedVideo = null;
        _pickedThumbnail = null;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoName =
        _pickedVideo != null ? _pickedVideo!.path.split('/').last : 'Видео не выбрано';
    final thumbName =
        _pickedThumbnail != null ? _pickedThumbnail!.path.split('/').last : 'Обложка не выбрана';

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить видео')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название')),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Описание')),
            const SizedBox(height: 12),
            Text('Выбранное видео: $videoName'),
            const SizedBox(height: 6),
            Text('Выбранная обложка: $thumbName'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_library),
                  label: const Text('Выбрать видео'),
                  onPressed: _isUploading ? null : _pickVideo,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Выбрать обложку (опц.)'),
                  onPressed: _isUploading ? null : _pickThumbnail,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isUploading) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Text('${(_progress * 100).toStringAsFixed(0)}%'),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: Text(_isUploading ? 'Загрузка...' : 'Загрузить'),
              onPressed: _isUploading ? null : _upload,
            ),
          ],
        ),
      ),
    );
  }
}
