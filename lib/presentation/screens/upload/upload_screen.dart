
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

import '../camera/live_filter_screen.dart';
import '../filters/photo_filter_screen.dart';

enum _Source { gallery, photo, video, cameraFilters }

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
            _SourceTile(
              icon: Icons.face_retouching_natural,
              label: 'Abrir cámara con filtros',
              onTap: () =>
                  Navigator.pop(sheetContext, _Source.cameraFilters),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null && mounted) {
      await _pick(source);
    }
  }

  Future<void> _pick(_Source source) async {
    // Abre la pantalla de cámara con filtros en vivo.
    if (source == _Source.cameraFilters) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const LiveFilterScreen(),
        ),
      );
      return;
    }

    XFile? picked;

    try {
      switch (source) {
        case _Source.gallery:
          picked = await _picker.pickMedia(
            imageQuality: 85,
            maxWidth: 1920,
          );
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

        case _Source.cameraFilters:
          return;
      }
    } catch (error) {
      debugPrint('Error al seleccionar archivo: $error');
      _showMessage(
        'No se pudo abrir la cámara o la galería. Revisa los permisos.',
      );
      return;
    }

    if (picked == null) return;

    final bool isVideo = source == _Source.video ||
        (source == _Source.gallery && _looksLikeVideo(picked));

    VideoPlayerController? controller;

    if (isVideo) {
      controller = VideoPlayerController.file(File(picked.path));

      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        await controller.play();
      } catch (error) {
        debugPrint('Error al abrir video: $error');
        await controller.dispose();
        _showMessage('No se pudo abrir ese video.');
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      previous?.dispose();
    });
  }

  void _togglePlay() {
    final video = _video;
    if (video == null || !video.value.isInitialized) return;

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
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  void _fail(String message) {
    if (!mounted) return;

    setState(() {
      _uploading = false;
    });

    _showMessage(message);
  }

  // Abre los filtros y utiliza la imagen resultante para publicar.
  Future<void> _testPhotoFilters() async {
    final file = _file;

    if (file == null || _isVideo || _uploading) return;

    final String? filteredPath = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => PhotoFilterScreen(
          imagePath: file.path,
        ),
      ),
    );

    if (!mounted || filteredPath == null) return;

    final filteredFile = File(filteredPath);

    if (!await filteredFile.exists()) {
      _showMessage('No se encontró la imagen con los filtros.');
      return;
    }

    setState(() {
      _file = XFile(
        filteredPath,
        mimeType: 'image/png',
      );
      _isVideo = false;
      _uploadedUrl = null;
      _progress = 0;
    });

    _showMessage('Foto actualizada con los filtros.');
  }

  // Muestra la vista previa de la foto o el video seleccionado.
  Widget _buildPreview(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: _file == null
          ? InkWell(
              onTap: _openSources,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 56,
                  ),
                  SizedBox(height: 12),
                  Text('Selecciona una foto o un video'),
                  SizedBox(height: 8),
                  Text('Toca aquí para elegir el archivo'),
                ],
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (_isVideo && _video != null)
                  _buildVideoPreview()
                else
                  Image.file(
                    File(_file!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('No se pudo mostrar la imagen.'),
                      );
                    },
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: _uploading ? null : _openSources,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Cambiar'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildVideoPreview() {
    final video = _video;

    if (video == null || !video.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: video.value.aspectRatio,
            child: VideoPlayer(video),
          ),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: video,
          builder: (context, value, child) {
            return IconButton(
              onPressed: _togglePlay,
              iconSize: 64,
              color: Colors.white,
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
            );
          },
        ),
      ],
    );
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
          if (mounted) {
            setState(() {
              _progress = value;
            });
          }
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
        ..showSnackBar(
          const SnackBar(
            content: Text('Publicación creada'),
          ),
        );

      navigator.pop();
    } on CloudinaryException catch (error) {
      _fail(error.message);
    } on StateError catch (error) {
      _fail(error.message);
    } on FirebaseException catch (error) {
      _fail('No se pudo guardar la publicación (${error.code})');
    } catch (error) {
      debugPrint('Error al publicar: $error');
      _fail('No se pudo publicar. Inténtalo de nuevo.');
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
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
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
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPreview(context),
                        const SizedBox(height: 12),

                        if (_file != null && !_isVideo)
                          OutlinedButton.icon(
                            onPressed:
                                _uploading ? null : _testPhotoFilters,
                            icon: const Icon(
                              Icons.face_retouching_natural,
                            ),
                            label: const Text('Probar filtros'),
                          ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _captionCtrl,
                          enabled: !_uploading,
                          maxLength: 150,
                          minLines: 1,
                          maxLines: 3,
                          textCapitalization:
                              TextCapitalization.sentences,
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
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
