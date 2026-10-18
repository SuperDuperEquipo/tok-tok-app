
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../widgets/filters/face_filter_painter.dart';

class PhotoFilterScreen extends StatefulWidget {
  final String imagePath;

  const PhotoFilterScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<PhotoFilterScreen> createState() => _PhotoFilterScreenState();
}

class _PhotoFilterScreenState extends State<PhotoFilterScreen> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  ui.Image? _originalImage;
  ui.Image? _skullImage;
  ui.Image? _santaHatImage;

  List<Face> _faces = [];

  bool _showSkull = false;
  bool _showSantaHat = false;
  bool _isLoading = true;
  bool _isGenerating = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPhotoAndDetectFaces();
  }

  Future<void> _loadPhotoAndDetectFaces() async {
    try {
      // Carga los dos filtros PNG.
      final skull = await loadFilterAsset(
        'assets/filtros/filtro1.png',
      );

      final santaHat = await loadFilterAsset(
        'assets/filtros/filtro2.png',
      );

      // Lee la foto que se recibió desde la pantalla anterior.
      final File photoFile = File(widget.imagePath);
      final Uint8List photoBytes = await photoFile.readAsBytes();

      final ui.Codec codec = await ui.instantiateImageCodec(
        photoBytes,
      );

      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image photoImage = frame.image;

      codec.dispose();

      // Detecta los rostros de la foto original.
      final InputImage inputImage = InputImage.fromFilePath(
        widget.imagePath,
      );

      final List<Face> detectedFaces =
          await _faceDetector.processImage(inputImage);

      if (!mounted) {
        photoImage.dispose();
        skull.dispose();
        santaHat.dispose();
        return;
      }

      setState(() {
        _originalImage = photoImage;
        _skullImage = skull;
        _santaHatImage = santaHat;
        _faces = detectedFaces;
        _isLoading = false;

        if (detectedFaces.isEmpty) {
          _errorMessage =
              'No se detectó ningún rostro. Prueba con otra foto.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'No se pudo cargar la foto o detectar el rostro.';
      });

      debugPrint('Error al cargar la foto: $error');
    }
  }

  Future<void> _useFilteredPhoto() async {
    if (_originalImage == null) return;

    if (_showSkull && _showSantaHat && _faces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se detectó un rostro para aplicar los filtros.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Genera una imagen nueva con los filtros incorporados.
      final Uint8List filteredBytes =
          await composeFilteredImageBytes(
        originalImage: _originalImage!,
        faces: _faces,
        skull: _showSkull ? _skullImage : null,
        santaHat: _showSantaHat ? _santaHatImage : null,
      );

      // Guarda temporalmente el resultado dentro de la app.
      final String outputPath =
          '${Directory.systemTemp.path}'
          '${Platform.pathSeparator}'
          'toktok_filtered_${DateTime.now().microsecondsSinceEpoch}.png';

      final File outputFile = File(outputPath);

      await outputFile.writeAsBytes(
        filteredBytes,
        flush: true,
      );

      if (!mounted) return;

      // Devuelve la ruta a la pantalla que abrió este filtro.
      Navigator.pop(context, outputFile.path);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo generar la imagen con los filtros.',
          ),
        ),
      );

      debugPrint('Error al generar la imagen: $error');
    }
  }

  @override
  void dispose() {
    _faceDetector.close();

    _originalImage?.dispose();
    _skullImage?.dispose();
    _santaHatImage?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros faciales'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_originalImage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage ?? 'No se pudo abrir la imagen.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: AspectRatio(
                aspectRatio:
                    _originalImage!.width / _originalImage!.height,
                child: CustomPaint(
                  painter: _PhotoFilterPainter(
                    originalImage: _originalImage!,
                    faces: _faces,
                    skull: _showSkull ? _skullImage : null,
                    santaHat:
                        _showSantaHat ? _santaHatImage : null,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.deepOrange,
              ),
            ),
          ),

        SwitchListTile(
          title: const Text('Calavera de Halloween'),
          subtitle: const Text('Mostrar el filtro de calavera'),
          value: _showSkull,
          onChanged: (value) {
            setState(() {
              _showSkull = value;
            });
          },
        ),

        SwitchListTile(
          title: const Text('Gorro de Santa'),
          subtitle: const Text('Mostrar el gorro navideño'),
          value: _showSantaHat,
          onChanged: (value) {
            setState(() {
              _showSantaHat = value;
            });
          },
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : _useFilteredPhoto,
              child: _isGenerating
                  ? const CircularProgressIndicator()
                  : const Text('Usar foto'),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pinta la foto original y los filtros seleccionados en la vista previa.
class _PhotoFilterPainter extends CustomPainter {
  final ui.Image originalImage;
  final List<Face> faces;
  final ui.Image? skull;
  final ui.Image? santaHat;

  _PhotoFilterPainter({
    required this.originalImage,
    required this.faces,
    required this.skull,
    required this.santaHat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / originalImage.width;
    final double scaleY = size.height / originalImage.height;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final Rect imageRect = Rect.fromLTWH(
      0,
      0,
      originalImage.width.toDouble(),
      originalImage.height.toDouble(),
    );

    canvas.drawImageRect(
      originalImage,
      imageRect,
      imageRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    for (final Face face in faces) {
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
  bool shouldRepaint(covariant _PhotoFilterPainter oldDelegate) {
    return oldDelegate.originalImage != originalImage ||
        oldDelegate.skull != skull ||
        oldDelegate.santaHat != santaHat ||
        oldDelegate.faces != faces;
  }
}
