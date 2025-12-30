import 'package:uuid/uuid.dart';

enum MessageRole { user, assistant }

enum MessageStatus { sending, streaming, complete, error }

class Message {
  final String id;
  final MessageRole role;
  String content;
  MessageStatus status;
  final DateTime timestamp;

  Message({
    String? id,
    required this.role,
    required this.content,
    this.status = MessageStatus.complete,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isStreaming => status == MessageStatus.streaming;

  Message copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      role: role,
      content: content ?? this.content,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }
}
