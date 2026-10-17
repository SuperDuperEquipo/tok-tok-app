import 'dart:async';

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/datasources/posts_service.dart';

class DiscoverProvider extends ChangeNotifier {
  final PostsService _service = PostsService();
  StreamSubscription<List<VideoPost>>? _sub;

  bool initialLoading = true;
  String? error;
  List<VideoPost> videos = [];

  /// Escucha los posts de Firestore en tiempo real
  void listenPosts() {
    _sub?.cancel();
    _sub = _service.watchPosts().listen(
      (posts) {
        videos = posts;
        initialLoading = false;
        error = null;
        notifyListeners();
      },
      onError: (_) {
        error = 'No se pudieron cargar las publicaciones';
        initialLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}