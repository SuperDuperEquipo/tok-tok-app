import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toktok/domain/entities/video_post.dart';

class PostModel {
  static VideoPost fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return VideoPost(
      id: doc.id,
      caption: data['caption'] ?? '',
      videoUrl: data['url'] ?? '',
      isVideo: (data['type'] ?? 'image') == 'video',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      views: (data['views'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? const []),
    );
  }
}