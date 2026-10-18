
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../widgets/filters/face_filter_painter.dart';

class LiveFilterScreen extends StatefulWidget {
  const LiveFilterScreen({super.key});

  @override
  State<LiveFilterScreen> createState() => _LiveFilterScreenState();
}

class _LiveFilterScreenState extends State<LiveFilterScreen> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  CameraController? _cameraController;

  ui.Image? _skullImage;
  ui.Image? _santaHatImage;

  List<Face> _faces = [];
  Size? _imageSize;

  bool _showSkull = false;
  bool _showSantaHat = false;
  bool _isProcessing = false;
  bool _isInitializing = true;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Carga los mismos filtros utilizados en las fotografías.
      final skull = await loadFilterAsset(
        'assets/filtros/filtro1.png',
      );

      final santaHat = await loadFilterAsset(
        'assets/filtros/filtro2.png',
      );

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        skull.dispose();
        santaHat.dispose();
        throw Exception('No se encontraron cámaras.');
      }

      // Prefiere la cámara frontal.
      final camera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : Platform.isIOS
                ? ImageFormatGroup.bgra8888
                : ImageFormatGroup.unknown,
      );

      await controller.initialize();

      if (!mounted) {
        skull.dispose();
        santaHat.dispose();
        await controller.dispose();
        return;
      }

      _skullImage = skull;
      _santaHatImage = santaHat;
      _cameraController = controller;

      setState(() {
        _isInitializing = false;
      });

      await controller.startImageStream(_processCameraImage);
    } catch (error, stackTrace) {
      debugPrint('Error al inicializar la cámara: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage =
            'No se pudo iniciar la cámara. '
            'Revisa los permisos e inténtalo de nuevo.';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !mounted) return;

    _isProcessing = true;

    try {
      final controller = _cameraController;

      if (controller == null || !controller.value.isInitialized) {
        return;
      }

      final inputImage = _inputImageFromCameraImage(
        image,
        controller.description,
        controller.value.deviceOrientation,
      );

      if (inputImage == null) return;

      final rotation = inputImage.metadata?.rotation;

      // Las coordenadas del rostro se interpretan en la orientación
      // corregida que se entrega al detector.
      final Size detectedImageSize =
          rotation == InputImageRotation.rotation90deg ||
                  rotation == InputImageRotation.rotation270deg
              ? Size(
                  image.height.toDouble(),
                  image.width.toDouble(),
                )
              : Size(
                  image.width.toDouble(),
                  image.height.toDouble(),
                );

      final faces = await _faceDetector.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        _faces = faces;
        _imageSize = detectedImageSize;
      });
    } catch (error) {
      debugPrint('Error al detectar rostros: $error');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(
    CameraImage image,
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    final InputImageRotation? rotation =
        _calculateImageRotation(camera, deviceOrientation);

    if (rotation == null || image.planes.length != 1) {
      return null;
    }

    final InputImageFormat? format =
        InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    // ML Kit espera NV21 en Android y BGRA8888 en iOS.
    if (Platform.isAndroid && format != InputImageFormat.nv21) {
      return null;
    }

    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      return null;
    }

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _calculateImageRotation(
    CameraDescription camera,
    DeviceOrientation deviceOrientation,
  ) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(
        camera.sensorOrientation,
      );
    }

    const orientations = <DeviceOrientation, int>{
      DeviceOrientation.portraitUp: 0,
      DeviceOrientation.landscapeLeft: 90,
      DeviceOrientation.portraitDown: 180,
      DeviceOrientation.landscapeRight: 270,
    };

    final deviceRotation = orientations[deviceOrientation];

    if (deviceRotation == null) return null;

    final int rotationDegrees;

    if (camera.lensDirection == CameraLensDirection.front) {
      rotationDegrees =
          (camera.sensorOrientation + deviceRotation) % 360;
    } else {
      rotationDegrees =
          (camera.sensorOrientation - deviceRotation + 360) % 360;
    }

    return InputImageRotationValue.fromRawValue(rotationDegrees);
  }

  Future<void> _closeCamera() async {
    final controller = _cameraController;
    _cameraController = null;

    if (controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (error) {
        debugPrint('Error al detener la cámara: $error');
      }

      await controller.dispose();
    }
  }

  @override
  void dispose() {
    unawaited(_disposeResources());
    super.dispose();
  }

  Future<void> _disposeResources() async {
    await _closeCamera();
    await _faceDetector.close();

    _skullImage?.dispose();
    _santaHatImage?.dispose();

    _skullImage = null;
    _santaHatImage = null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Filtros en vivo'),
      ),
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : controller == null ||
                      !controller.value.isInitialized
                  ? const Center(
                      child: Text(
                        'La cámara no está disponible.',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(controller),

                              if (_imageSize != null)
                                CustomPaint(
                                  painter: _LiveFaceFilterPainter(
                                    imageSize: _imageSize!,
                                    faces: _faces,
                                    skull: _showSkull
                                        ? _skullImage
                                        : null,
                                    santaHat: _showSantaHat
                                        ? _santaHatImage
                                        : null,
                                    mirrorHorizontally:
                                        controller.description
                                                .lensDirection ==
                                            CameraLensDirection.front,
                                  ),
                                  child: const SizedBox.expand(),
                                ),

                              if (_faces.isEmpty)
                                const Positioned(
                                  top: 16,
                                  left: 16,
                                  right: 16,
                                  child: Text(
                                    'Coloca tu rostro frente a la cámara',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Container(
                          color: Colors.black,
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            12,
                            16,
                            24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: Colors.white,
                                activeTrackColor: Colors.purple,
                                title: const Text(
                                  'Calavera de Halloween',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                value: _showSkull,
                                onChanged: (value) {
                                  setState(() {
                                    _showSkull = value;
                                  });
                                },
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: Colors.white,
                                activeTrackColor: Colors.red,
                                title: const Text(
                                  'Gorro de Santa',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                value: _showSantaHat,
                                onChanged: (value) {
                                  setState(() {
                                    _showSantaHat = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Esta versión es una vista previa. '
                                'Todavía no graba videos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

/// Dibuja los filtros sobre el área de vista previa de la cámara.
class _LiveFaceFilterPainter extends CustomPainter {
  final Size imageSize;
  final List<Face> faces;
  final ui.Image? skull;
  final ui.Image? santaHat;
  final bool mirrorHorizontally;

  _LiveFaceFilterPainter({
    required this.imageSize,
    required this.faces,
    required this.skull,
    required this.santaHat,
    required this.mirrorHorizontally,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    // Mantiene la misma escala que una imagen ajustada con BoxFit.cover.
    final scale = (size.width / imageSize.width)
        .clamp(0.0, double.infinity);

    final scaleY = size.height / imageSize.height;
    final effectiveScale = scale > scaleY ? scale : scaleY;

    final offsetX =
        (size.width - imageSize.width * effectiveScale) / 2;
    final offsetY =
        (size.height - imageSize.height * effectiveScale) / 2;

    canvas.save();

    canvas.translate(offsetX, offsetY);
    canvas.scale(effectiveScale);

    if (mirrorHorizontally) {
      canvas.translate(imageSize.width, 0);
      canvas.scale(-1, 1);
    }

    for (final face in faces) {
      paintFaceFilters(
        canvas: canvas,
        face: face,
        skull: skull,
        santaHat: santaHat,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiveFaceFilterPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.faces != faces ||
        oldDelegate.skull != skull ||
        oldDelegate.santaHat != santaHat ||
        oldDelegate.mirrorHorizontally != mirrorHorizontally;
  }
}
