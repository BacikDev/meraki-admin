import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  final SupabaseClient supabase = Supabase.instance.client;

  static const String bucketName = 'pattern-images';

  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  Future<String?> pickAndUploadPatternImage() {
    return _pickAndUploadImage(
      folder: 'patterns',
      filePrefix: 'pattern',
    );
  }

  Future<String?> pickAndUploadCategoryImage() {
    return _pickAndUploadImage(
      folder: 'categories',
      filePrefix: 'category',
    );
  }

  Future<String?> _pickAndUploadImage({
    required String folder,
    required String filePrefix,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw Exception(
          'No fue posible leer los datos de la imagen seleccionada.',
        );
      }

      if (file.size > maxFileSizeBytes) {
        throw Exception(
          'La imagen supera el tamaño máximo permitido de 10 MB.',
        );
      }

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception(
          'No hay una sesión activa. Cerrá sesión e ingresá nuevamente.',
        );
      }

      debugPrint('Usuario autenticado: ${user.id}');
      debugPrint('Bucket: $bucketName');
      debugPrint('Archivo: ${file.name}');
      debugPrint('Tamaño: ${file.size} bytes');

      return await uploadImage(
        bytes: bytes,
        originalFileName: file.name,
        folder: folder,
        filePrefix: filePrefix,
      );
    } on StorageException catch (error, stackTrace) {
      debugPrint(
        'StorageException: '
        'statusCode=${error.statusCode}, '
        'message=${error.message}',
      );
      debugPrintStack(stackTrace: stackTrace);

      _showError(
        title: 'Error de Storage',
        message: [
          if (error.statusCode != null) 'Código ${error.statusCode}',
          error.message,
        ].join(' — '),
      );

      return null;
    } catch (error, stackTrace) {
      debugPrint('Error al seleccionar o subir imagen: $error');
      debugPrintStack(stackTrace: stackTrace);

      _showError(
        title: 'No se pudo subir la imagen',
        message: _cleanErrorMessage(error),
      );

      return null;
    }
  }

  Future<String> uploadPatternImage({
    required Uint8List bytes,
    required String originalFileName,
  }) {
    return uploadImage(
      bytes: bytes,
      originalFileName: originalFileName,
      folder: 'patterns',
      filePrefix: 'pattern',
    );
  }

  Future<String> uploadCategoryImage({
    required Uint8List bytes,
    required String originalFileName,
  }) {
    return uploadImage(
      bytes: bytes,
      originalFileName: originalFileName,
      folder: 'categories',
      filePrefix: 'category',
    );
  }

  Future<String> uploadImage({
    required Uint8List bytes,
    required String originalFileName,
    required String folder,
    required String filePrefix,
  }) async {
    if (bytes.isEmpty) {
      throw Exception('La imagen seleccionada está vacía.');
    }

    final extension = _getFileExtension(originalFileName);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final safePrefix = _sanitizePathPart(filePrefix);
    final safeFolder = _sanitizePathPart(folder);

    final fileName = '${safePrefix}_$timestamp.$extension';
    final filePath = '$safeFolder/$fileName';

    debugPrint('Intentando subir en: $bucketName/$filePath');

    try {
      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: _getContentType(extension),
            ),
          );

      final publicUrl = supabase.storage
          .from(bucketName)
          .getPublicUrl(filePath);

      debugPrint('Imagen subida correctamente: $publicUrl');

      return publicUrl;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw Exception(
        'No se pudo subir la imagen: ${_cleanErrorMessage(error)}',
      );
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    if (imageUrl.trim().isEmpty) {
      return;
    }

    final filePath = _extractFilePathFromPublicUrl(imageUrl);

    if (filePath == null || filePath.isEmpty) {
      debugPrint(
        'La URL no pertenece al bucket $bucketName: $imageUrl',
      );
      return;
    }

    try {
      await supabase.storage.from(bucketName).remove([filePath]);

      debugPrint('Imagen eliminada: $filePath');
    } on StorageException catch (error) {
      debugPrint(
        'Error al eliminar imagen: '
        '${error.statusCode} ${error.message}',
      );

      rethrow;
    } catch (error) {
      throw Exception(
        'No se pudo eliminar la imagen: '
        '${_cleanErrorMessage(error)}',
      );
    }
  }

  Future<void> deletePatternImage(String imageUrl) {
    return deleteImage(imageUrl);
  }

  Future<void> deleteCategoryImage(String imageUrl) {
    return deleteImage(imageUrl);
  }

  String? _extractFilePathFromPublicUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      final bucketIndex = segments.indexOf(bucketName);

      if (bucketIndex == -1 ||
          bucketIndex + 1 >= segments.length) {
        return null;
      }

      return segments
          .sublist(bucketIndex + 1)
          .map(Uri.decodeComponent)
          .join('/');
    } catch (error) {
      debugPrint('No se pudo interpretar la URL: $error');
      return null;
    }
  }

  String _getFileExtension(String fileName) {
    final normalizedName = fileName.trim().toLowerCase();
    final lastDot = normalizedName.lastIndexOf('.');

    if (lastDot == -1 ||
        lastDot == normalizedName.length - 1) {
      return 'jpg';
    }

    final extension = normalizedName.substring(lastDot + 1);

    const supportedExtensions = {
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    };

    return supportedExtensions.contains(extension)
        ? extension
        : 'jpg';
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      case 'gif':
        return 'image/gif';

      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _sanitizePathPart(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  String _cleanErrorMessage(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .trim();
  }

  void _showError({
    required String title,
    required String message,
  }) {
    Get.snackbar(
      title,
      message,
      duration: const Duration(seconds: 8),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      margin: const EdgeInsets.all(18),
    );
  }
}