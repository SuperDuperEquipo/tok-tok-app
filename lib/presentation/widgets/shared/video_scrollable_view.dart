import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/presentation/widgets/shared/video_buttons.dart';
import 'package:toktok/presentation/widgets/video/fullscreen_player.dart';

class VideoScrollableView extends StatelessWidget {
  final List<VideoPost> videos;

  const VideoScrollableView({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: videos.length,
      findChildIndexCallback: (key) {
        if (key is ValueKey<String>) {
          final index = videos.indexWhere((v) => v.id == key.value);
          return index == -1 ? null : index;
        }
        return null;
      },
      itemBuilder: (context, index) {
        final post = videos[index];

        return Stack(
          key: ValueKey(post.id),
          children: [
            SizedBox.expand(
              child: post.isVideo
                  ? FullScreenPlayer(
                      videoUrl: post.videoUrl,
                      caption: post.caption,
                      author: post.authorName,
                    )
                  : FullScreenImage(
                      imageUrl: post.videoUrl,
                      caption: post.caption,
                      author: post.authorName,
                    ),
            ),

            Positioned(
              bottom: 40,
              right: 20,
              child: VideoButtons(video: post),
            ),
          ],
        );
      },
    );
  }
}