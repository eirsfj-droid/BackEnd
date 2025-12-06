// lib/services/video_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class UploadResult {
  final String downloadUrl;
  final String storagePath;
  UploadResult(this.downloadUrl, this.storagePath);
}

class VideoUploadResult {
  final UploadResult video;
  final UploadResult? thumbnail; 
  VideoUploadResult({required this.video, this.thumbnail});
}

class VideoService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  
  Future<File?> pickVideoFromGallery() async {
    final XFile? picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  
  Future<File?> pickThumbnailFromGallery() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return File(picked.path);
  }

  
  Future<File?> generateThumbnail(File videoFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final String? thumbPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 300,
        quality: 75,
      );
      if (thumbPath == null) return null;
      return File(thumbPath);
    } catch (e) {
      
      return null;
    }
  }

  
  Future<UploadResult> uploadVideoFile(
    File file, {
    String? userId,
    void Function(double progress)? onProgress,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storagePath = 'videos/${userId ?? "anon"}/$fileName';
    final ref = _storage.ref().child(storagePath);

    final contentType = _guessContentType(file.path);
    final metadata = SettableMetadata(contentType: contentType);

    final uploadTask = ref.putFile(file, metadata);

    uploadTask.snapshotEvents.listen((TaskSnapshot snap) {
      final transferred = snap.bytesTransferred;
      final total = snap.totalBytes ?? 1;
      final prog = transferred / (total == 0 ? 1 : total);
      if (onProgress != null) onProgress(prog);
    });

    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return UploadResult(downloadUrl, snapshot.ref.fullPath);
  }

  
  Future<UploadResult> uploadThumbnailFile(
    File file, {
    String? userId,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final storagePath = 'thumbnails/${userId ?? "anon"}/$fileName';
    final ref = _storage.ref().child(storagePath);

    final ext = file.path.toLowerCase();
    final contentType = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';
    final metadata = SettableMetadata(contentType: contentType);

    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await ref.getDownloadURL();

    return UploadResult(downloadUrl, ref.fullPath);
  }

  
  Future<VideoUploadResult> uploadVideoWithThumbnail({
    required File videoFile,
    File? providedThumbnailFile, 
    String? userId,
    void Function(double progress)? onVideoProgress,
  }) async {
   
    final videoUpload = await uploadVideoFile(
      videoFile,
      userId: userId,
      onProgress: onVideoProgress,
    );

   
    File? thumbFile = providedThumbnailFile;
    if (thumbFile == null) {
      thumbFile = await generateThumbnail(videoFile);
    }

    UploadResult? thumbUpload;
    if (thumbFile != null) {
      thumbUpload = await uploadThumbnailFile(thumbFile, userId: userId);
    }

    return VideoUploadResult(video: videoUpload, thumbnail: thumbUpload);
  }

  String _guessContentType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.mp4')) return 'video/mp4';
    if (p.endsWith('.mov')) return 'video/quicktime';
    if (p.endsWith('.webm')) return 'video/webm';
    if (p.endsWith('.mkv')) return 'video/x-matroska';
    return 'application/octet-stream';
  }
}
