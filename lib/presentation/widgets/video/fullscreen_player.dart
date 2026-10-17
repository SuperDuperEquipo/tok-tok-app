import 'package:flutter/material.dart';
import 'package:toktok/presentation/widgets/video/video_background.dart';
import 'package:video_player/video_player.dart';

class FullScreenPlayer extends StatefulWidget {
  final String videoUrl;
  final String caption;
  final String author;

  const FullScreenPlayer({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.author = '',
  });

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late final VideoPlayerController controller;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initFuture = _init();
  }

  Future<void> _init() async {
    await controller.initialize();
    await controller.setVolume(0);
    await controller.setLooping(true);
    await controller.play();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudo cargar el video'));
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final size = controller.value.size;

        return GestureDetector(
          onTap: () {
            if (controller.value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: VideoPlayer(controller),
                ),
              ),
              VideoBackground(stops: const [0.7, 1.0]),
              Positioned(
                bottom: 50,
                left: 20,
                child: PostCaption(author: widget.author, caption: widget.caption),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String caption;
  final String author;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.caption,
    this.author = '',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorBuilder: (context, error, stack) {
            debugPrint('Error cargando imagen ($imageUrl): $error');
            return const Center(
              child: Icon(Icons.broken_image_outlined, size: 48),
            );
          },
        ),
        VideoBackground(stops: const [0.7, 1.0]),
        Positioned(
          bottom: 50,
          left: 20,
          child: PostCaption(author: author, caption: caption),
        ),
      ],
    );
  }
}
class PostCaption extends StatelessWidget {
  final String author;
  final String caption;

  const PostCaption({super.key, required this.author, required this.caption});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: size.width * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (author.isNotEmpty)
            Text(
              '@$author',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          if (caption.isNotEmpty)
            Text(caption, maxLines: 2, style: textTheme.titleLarge),
        ],
      ),
    );
  }
}