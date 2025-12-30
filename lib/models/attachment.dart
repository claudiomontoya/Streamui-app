import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

/// Tipos de archivos adjuntos soportados
enum AttachmentType { image, document, audio, video, other }

/// Modelo de archivo adjunto
class Attachment {
  final String id;
  final String name;
  final String filePath;
  final int size;
  final AttachmentType type;
  final String? mimeType;

  Attachment({
    required this.id,
    required this.name,
    required this.filePath,
    required this.size,
    AttachmentType? type,
    this.mimeType,
  }) : type = type ?? _inferType(filePath, mimeType);

  /// Infiere el tipo de archivo basado en la extensión o MIME
  static AttachmentType _inferType(String filePath, String? mimeType) {
    final mime = mimeType ?? lookupMimeType(filePath) ?? '';

    if (mime.startsWith('image/')) return AttachmentType.image;
    if (mime.startsWith('video/')) return AttachmentType.video;
    if (mime.startsWith('audio/')) return AttachmentType.audio;
    if (mime.startsWith('application/pdf') ||
        mime.startsWith('application/msword') ||
        mime.startsWith('application/vnd.') ||
        mime.startsWith('text/')) {
      return AttachmentType.document;
    }
    return AttachmentType.other;
  }

  /// Obtiene la extensión del archivo
  String get extension => path.extension(name).toLowerCase();

  /// Formatea el tamaño del archivo
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Ícono según el tipo de archivo
  String get iconName {
    switch (type) {
      case AttachmentType.image:
        return 'image';
      case AttachmentType.video:
        return 'video_file';
      case AttachmentType.audio:
        return 'audio_file';
      case AttachmentType.document:
        return 'description';
      case AttachmentType.other:
        return 'insert_drive_file';
    }
  }
}
