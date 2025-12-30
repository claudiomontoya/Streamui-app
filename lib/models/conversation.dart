import 'package:uuid/uuid.dart';
import 'message.dart';

/// Modelo de conversación para el historial
class Conversation {
  final String id;
  String title;
  final List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  Conversation({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        title = title ?? 'Nueva conversación',
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Genera un título basado en el primer mensaje del usuario
  void generateTitle() {
    final firstUserMessage = messages.where((m) => m.isUser).firstOrNull;
    if (firstUserMessage != null) {
      final content = firstUserMessage.content;
      title = content.length > 30 ? '${content.substring(0, 30)}...' : content;
    }
  }

  /// Obtiene el último mensaje
  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Obtiene un preview del último mensaje
  String get preview {
    if (messages.isEmpty) return 'Sin mensajes';
    final last = messages.last;
    final content = last.content;
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  Conversation copyWith({
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
