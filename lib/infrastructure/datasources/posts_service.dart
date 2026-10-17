import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/models/post_model.dart';

class PostsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _post =>
      _db.collection('post');

  Stream<List<VideoPost>> watchPosts() {
    return _post
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PostModel.fromDoc).toList());
  }

  Future<void> createPost({
    required String url,
    required String type,
    required String caption,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Debes iniciar sesión para publicar');

    await _post.add({
      'url': url,
      'type': type,
      'caption': caption.trim(),
      'authorId': user.uid,
      'authorName': user.displayName ?? 'usuario',
      'likes': 0,
      'views': 0,
      'likedBy': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleLike(String postId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _post.doc(postId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final likedBy = List<String>.from(snap.data()?['likedBy'] ?? const []);

      if (likedBy.contains(uid)) {
        tx.update(ref, {
          'likedBy': FieldValue.arrayRemove([uid]),
          'likes': FieldValue.increment(-1),
        });
      } else {
        tx.update(ref, {
          'likedBy': FieldValue.arrayUnion([uid]),
          'likes': FieldValue.increment(1),
        });
      }
    });
  }
}