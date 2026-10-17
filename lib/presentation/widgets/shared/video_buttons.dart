import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:toktok/config/helpers/human_formats.dart';
import 'package:toktok/domain/entities/video_post.dart';
import 'package:toktok/infrastructure/datasources/auth_service.dart';
import 'package:toktok/infrastructure/datasources/posts_service.dart';

class VideoButtons extends StatelessWidget {
  final VideoPost video;

  const VideoButtons({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';
    final liked = video.isLikedBy(uid);

    return Column(
      children: [
        _CustomIconButton(
          value: video.likes,
          iconData: liked ? Icons.favorite : Icons.favorite_border,
          color: liked ? Colors.red : Colors.white,
          onPressed: () => PostsService().toggleLike(video.id),
        ),
        const SizedBox(height: 20),
        _CustomIconButton(
          value: video.views,
          iconData: Icons.remove_red_eye_outlined,
        ),
        const SizedBox(height: 20),
        SpinPerfect(
          infinite: true,
          duration: const Duration(seconds: 5),
          child: const _CustomIconButton(
            value: 0,
            iconData: Icons.play_circle_outline,
          ),
        ),
      ],
    );
  }
}

class _CustomIconButton extends StatelessWidget {
  final int value;
  final IconData iconData;
  final Color color;
  final VoidCallback? onPressed;

  const _CustomIconButton({
    required this.value,
    required this.iconData,
    this.color = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed ?? () {},
          icon: Icon(iconData, color: color, size: 30),
        ),
        if (value > 0)
          Text(HumanFormats.humanReadbleNumber(value.toDouble())),
      ],
    );
  }
}