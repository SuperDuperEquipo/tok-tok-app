import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudinaryException implements Exception {
  final String message;
  CloudinaryException(this.message);

  @override
  String toString() => message;
}

class CloudinaryService {
  static const String _cloudName = 'djvuvmjix';
  static const String _uploadPreset = 'toktok_uploads';

  Future<String> upload({
    required String path,
    required bool isVideo,
    void Function(double progress)? onProgress,
  }) async {
    final resourceType = isVideo ? 'video' : 'image';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload',
    );

    try {
      final request = _ProgressRequest('POST', uri, (sent, total) {
        if (total > 0) onProgress?.call((sent / total).clamp(0.0, 1.0));
      });
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', path));

      final response =
          await request.send().timeout(const Duration(minutes: 10));
      final body = await response.stream.bytesToString();
      final json = _decode(body);

      if (response.statusCode != 200) {
        throw CloudinaryException(_errorMessage(json));
      }

      final url = json['secure_url'];
      if (url is! String || url.isEmpty) {
        throw CloudinaryException('Cloudinary no devolvió la URL del archivo');
      }
      return url;
    } on CloudinaryException {
      rethrow;
    } on TimeoutException {
      throw CloudinaryException(
        'La subida tardó demasiado. Inténtalo de nuevo',
      );
    } catch (_) {
      throw CloudinaryException(
        'No se pudo subir el archivo. Revisa tu conexión e inténtalo de nuevo',
      );
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _errorMessage(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return 'No se pudo subir el archivo';
  }
}

class _ProgressRequest extends http.MultipartRequest {
  final void Function(int sent, int total) onProgress;

  _ProgressRequest(String method, Uri url, this.onProgress)
      : super(method, url);

  @override
  http.ByteStream finalize() {
    final total = contentLength;
    var sent = 0;

    final stream = super.finalize().transform<List<int>>(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) {
              sent += data.length;
              onProgress(sent, total);
              sink.add(data);
            },
          ),
        );

    return http.ByteStream(stream);
  }
}
