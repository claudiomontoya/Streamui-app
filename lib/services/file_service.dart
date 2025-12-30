import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/attachment.dart';

/// Servicio para manejar archivos adjuntos
class FileService {
  static const int maxFileSizeMB = 10;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  /// Tipos de archivo permitidos
  static const allowedExtensions = [
    // Imágenes
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',
    // Documentos
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'csv',
    // Código
    'json', 'xml', 'html', 'css', 'js', 'dart', 'py', 'java', 'kt',
    // Audio
    'mp3', 'wav', 'ogg', 'm4a',
    // Video
    'mp4', 'webm', 'mov',
  ];

  /// Selecciona archivos del dispositivo
  Future<List<Attachment>> pickFiles({bool allowMultiple = true}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: false,
        withReadStream: false,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      final attachments = <Attachment>[];

      for (final file in result.files) {
        if (file.path == null) continue;

        // Verificar tamaño
        if (file.size > maxFileSizeBytes) {
          throw FileServiceException(
            'El archivo "${file.name}" excede el límite de ${maxFileSizeMB}MB',
          );
        }

        attachments.add(Attachment(
          id: const Uuid().v4(),
          name: file.name,
          filePath: file.path!,
          size: file.size,
        ));
      }

      return attachments;
    } catch (e) {
      if (e is FileServiceException) rethrow;
      throw FileServiceException('Error al seleccionar archivos: $e');
    }
  }

  /// Selecciona una imagen de la galería o cámara
  Future<Attachment?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      if (file.path == null) return null;

      if (file.size > maxFileSizeBytes) {
        throw FileServiceException(
          'La imagen excede el límite de ${maxFileSizeMB}MB',
        );
      }

      return Attachment(
        id: const Uuid().v4(),
        name: file.name,
        filePath: file.path!,
        size: file.size,
        type: AttachmentType.image,
      );
    } catch (e) {
      if (e is FileServiceException) rethrow;
      throw FileServiceException('Error al seleccionar imagen: $e');
    }
  }
}

class FileServiceException implements Exception {
  final String message;
  FileServiceException(this.message);

  @override
  String toString() => message;
}
