
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

Future<ui.Image> loadFilterAsset(String assetPath) async {
  final ByteData data = await rootBundle.load(assetPath);

  final Uint8List bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );

  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.FrameInfo frame = await codec.getNextFrame();

  codec.dispose();

  return frame.image;
}

void paintFaceFilters({
  required Canvas canvas,
  required Face face,
  required ui.Image? skull,
  required ui.Image? santaHat,
  double santaHatScale = 1.9,
}) {
  final Rect faceRect = face.boundingBox;
  final double angle = (face.headEulerAngleZ ?? 0) * math.pi / 180;

  if (skull != null) {
    final double width = faceRect.width * 2.45;
    final double height = width * skull.height / skull.width;

    _drawRotatedOverlay(
      canvas: canvas,
      image: skull,
      center: Offset(
        faceRect.center.dx,
        faceRect.center.dy - faceRect.height * 0.18,
      ),
      width: width,
      height: height,
      angle: angle,
    );
  }

  if (santaHat != null) {
    final double width = faceRect.width * santaHatScale;
    final double height = width * santaHat.height / santaHat.width;

    _drawRotatedOverlay(
      canvas: canvas,
      image: santaHat,
      center: Offset(
        faceRect.center.dx - faceRect.width * 0.12,
        faceRect.top - height * 0.08,
      ),
      width: width,
      height: height,
      angle: angle,
    );
  }
}

void _drawRotatedOverlay({
  required Canvas canvas,
  required ui.Image image,
  required Offset center,
  required double width,
  required double height,
  required double angle,
}) {
  canvas.save();

  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  final Rect destination = Rect.fromCenter(
    center: Offset.zero,
    width: width,
    height: height,
  );

  final Rect source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );

  canvas.drawImageRect(
    image,
    source,
    destination,
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );

  canvas.restore();
}

Future<Uint8List> composeFilteredImageBytes({
  required ui.Image originalImage,
  required List<Face> faces,
  required ui.Image? skull,
  required ui.Image? santaHat,
  double santaHatScale = 1.9,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);

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
      santaHatScale: santaHatScale,
    );
  }

  final ui.Picture picture = recorder.endRecording();
  final ui.Image result = await picture.toImage(
    originalImage.width,
    originalImage.height,
  );

  final ByteData? data = await result.toByteData(
    format: ui.ImageByteFormat.png,
  );

  picture.dispose();
  result.dispose();

  if (data == null) {
    throw Exception('No se pudo generar la imagen con los filtros.');
  }

  return data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
}
