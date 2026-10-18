import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toktok/config/theme/app_colors.dart';
import 'package:toktok/infrastructure/datasources/cloudinary_service.dart';
import 'package:toktok/infrastructure/datasources/posts_service.dart';
import 'package:toktok/presentation/widgets/auth/auth_background.dart';
import 'package:toktok/presentation/widgets/auth/gradient_button.dart';
import 'package:video_player/video_player.dart';

enum _Source { gallery, photo, video }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  static const Set<String> _videoExtensions = {
    'mp4',
    'mov',
    'm4v',
    'avi',
    'mkv',
    'webm',
    '3gp',
  };

  final ImagePicker _picker = ImagePicker();
  final CloudinaryService _cloudinary = CloudinaryService();
  final TextEditingController _captionCtrl = TextEditingController();

  XFile? _file;
  bool _isVideo = false;
  VideoPlayerController? _video;
  String? _uploadedUrl;
  bool _uploading = false;
  double _progress = 0;

  @override
  void dispose() {
    _video?.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeVideo(XFile file) {
    final mime = file.mimeType;
    if (mime != null && mime.startsWith('video/')) return true;
    if (mime != null && mime.startsWith('image/')) return false;
    final dot = file.path.lastIndexOf('.');
    if (dot == -1) return false;
    final extension = file.path.substring(dot + 1).toLowerCase();
    return _videoExtensions.contains(extension);
  }

  Future<void> _openSources() async {
    if (_uploading) return;

    final source = await showModalBottomSheet<_Source>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SourceTile(
              icon: Icons.photo_library_outlined,
              label: 'Elegir de la galería',
              onTap: () => Navigator.pop(sheetContext, _Source.gallery),
            ),
            _SourceTile(
              icon: Icons.photo_camera_outlined,
              label: 'Tomar una foto',
              onTap: () => Navigator.pop(sheetContext, _Source.photo),
            ),
            _SourceTile(
              icon: Icons.videocam_outlined,
              label: 'Grabar un video',
              onTap: () => Navigator.pop(sheetContext, _Source.video),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) await _pick(source);
  }

  Future<void> _pick(_Source source) async {
    XFile? picked;

    try {
      switch (source) {
        case _Source.gallery:
          picked = await _picker.pickMedia(imageQuality: 85, maxWidth: 1920);
          break;
        case _Source.photo:
          picked = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
            maxWidth: 1920,
          );
          break;
        case _Source.video:
          picked = await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 60),
          );
          break;
      }
    } catch (_) {
      _showMessage(
        'No se pudo abrir la cámara o la galería. Revisa los permisos',
      );
      return;
    }

    if (picked == null) return;

    final isVideo = source == _Source.video ||
        (source == _Source.gallery && _looksLikeVideo(picked));

    VideoPlayerController? controller;
    if (isVideo) {
      controller = VideoPlayerController.file(File(picked.path));
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
      } catch (_) {
        await controller.dispose();
        _showMessage('No se pudo abrir ese video');
        return;
      }
    }

    if (!mounted) {
      await controller?.dispose();
      return;
    }

    final previous = _video;
    setState(() {
      _file = picked;
      _isVideo = isVideo;
      _video = controller;
      _uploadedUrl = null;
      _progress = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => previous?.dispose());
  }

  void _togglePlay() {
    final video = _video;
    if (video == null) return;
    if (video.value.isPlaying) {
      video.pause();
    } else {
      video.play();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _uploading = false);
    _showMessage(message);
  }

  Future<void> _publish() async {
    final file = _file;
    if (file == null || _uploading) return;

    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _uploading = true;
      _progress = 0;
    });

    try {
      _uploadedUrl ??= await _cloudinary.upload(
        path: file.path,
        isVideo: _isVideo,
        onProgress: (value) {
          if (mounted) setState(() => _progress = value);
        },
      );

      await PostsService().createPost(
        url: _uploadedUrl!,
        type: _isVideo ? 'video' : 'image',
        caption: _captionCtrl.text,
      );

      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Publicación creada')));
      navigator.pop();
    } on CloudinaryException catch (e) {
      _fail(e.message);
    } on StateError catch (e) {
      _fail(e.message);
    } on FirebaseException catch (e) {
      _fail('No se pudo guardar la publicación (${e.code})');
    } catch (e) {
      debugPrint('Error al publicar: $e');
      _fail('No se pudo publicar. Inténtalo de nuevo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_uploading,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: const Text(
            'Nueva publicación',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: Stack(
          children: [
            const AuthBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    kToolbarHeight + 8,
                    24,
                    24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPreview(context),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _captionCtrl,
                          enabled: !_uploading,
                          maxLength: 150,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: 'Escribe una descripción...',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_uploading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _progress >= 1 ? null : _progress,
                              minHeight: 6,
                              color: AppColors.magenta,
                              backgroundColor: AppColors.border,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _progress >= 1
                                ? 'Publicando...'
                                : 'Subiendo ${(_progress * 100).round()}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        GradientButton(
                          label: 'Publicar',
                          loading: _uploading,
                          onPressed: _file == null ? null : _publish,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.45;
    final file = _file;

    if (file == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openSources,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.brandGlow,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Agrega una foto o un video',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Desde tu galería o con la cámara',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final video = _video;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            if (_isVideo && video != null)
              GestureDetector(
                onTap: _togglePlay,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: video.value.size.width,
                    height: video.value.size.height,
                    child: VideoPlayer(video),
                  ),
                ),
              )
            else
              Image.file(File(file.path), fit: BoxFit.cover),
            if (_isVideo && video != null)
              IgnorePointer(
                child: Center(
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: video,
                    builder: (context, value, _) => AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white70,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black54,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _uploading ? null : _openSources,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Cambiar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.magenta),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      onTap: onTap,
    );
  }
}
