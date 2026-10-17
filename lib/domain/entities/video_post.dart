/// Publicación del feed (video o imagen).
/// Se guarda en Firestore, colección "posts".
class VideoPost {
  final String id;
  final String caption;

  /// URL del archivo (Cloudinary). Puede ser un video o una imagen.
  final String videoUrl;
  final bool isVideo;
  final String authorId;
  final String authorName;
  final int likes;
  final int views;
  final List<String> likedBy;

  VideoPost({
    required this.id,
    required this.caption,
    required this.videoUrl,
    required this.isVideo,
    this.authorId = '',
    this.authorName = '',
    this.likes = 0,
    this.views = 0,
    this.likedBy = const [],
  });

  bool isLikedBy(String uid) => likedBy.contains(uid);
}