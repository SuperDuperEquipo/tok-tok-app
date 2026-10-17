import 'package:flutter/material.dart';

/// Pantalla para subir fotos y videos.
/// + guardar el post en Firestore.
class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva publicación')),
      body: const Center(
        child: Text('Aquí irá la subida de fotos y videos'),
      ),
    );
  }
}