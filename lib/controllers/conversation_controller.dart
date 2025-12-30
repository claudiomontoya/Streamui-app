import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/message.dart';

/// Controlador para gestionar múltiples conversaciones
class ConversationController extends ChangeNotifier {
  final List<Conversation> _conversations = [];
  String? _activeConversationId;

  List<Conversation> get conversations => List.unmodifiable(_conversations);

  Conversation? get activeConversation {
    if (_activeConversationId == null) return null;
    return _conversations.firstWhere(
      (c) => c.id == _activeConversationId,
      orElse: () => _conversations.first,
    );
  }

  String? get activeConversationId => _activeConversationId;

  bool get hasConversations => _conversations.isNotEmpty;

  /// Crea una nueva conversación y la activa
  Conversation createNewConversation() {
    final conversation = Conversation();
    _conversations.insert(0, conversation);
    _activeConversationId = conversation.id;
    notifyListeners();
    return conversation;
  }

  /// Activa una conversación existente
  void setActiveConversation(String conversationId) {
    if (_activeConversationId == conversationId) return;

    final exists = _conversations.any((c) => c.id == conversationId);
    if (exists) {
      _activeConversationId = conversationId;
      notifyListeners();
    }
  }

  /// Obtiene o crea la conversación activa
  Conversation getOrCreateActive() {
    if (_activeConversationId != null) {
      final active = _conversations.firstWhere(
        (c) => c.id == _activeConversationId,
        orElse: () => createNewConversation(),
      );
      return active;
    }
    return createNewConversation();
  }

  /// Agrega un mensaje a la conversación activa
  void addMessageToActive(Message message) {
    final conversation = getOrCreateActive();
    conversation.messages.add(message);
    conversation.updatedAt = DateTime.now();

    // Generar título si es el primer mensaje del usuario
    if (conversation.messages.where((m) => m.isUser).length == 1) {
      conversation.generateTitle();
    }

    // Mover al inicio de la lista
    _reorderToTop(conversation.id);
    notifyListeners();
  }

  /// Actualiza el último mensaje de la conversación activa
  void updateLastMessageInActive(String content, {MessageStatus? status}) {
    final conversation = activeConversation;
    if (conversation == null || conversation.messages.isEmpty) return;

    final lastIndex = conversation.messages.length - 1;
    final lastMessage = conversation.messages[lastIndex];

    conversation.messages[lastIndex] = lastMessage.copyWith(
      content: content,
      status: status,
    );
    conversation.updatedAt = DateTime.now();
    notifyListeners();
  }

  /// Obtiene los mensajes de la conversación activa
  List<Message> getActiveMessages() {
    return activeConversation?.messages ?? [];
  }

  /// Elimina una conversación
  void deleteConversation(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);

    // Si se eliminó la activa, activar otra o null
    if (_activeConversationId == conversationId) {
      _activeConversationId =
          _conversations.isNotEmpty ? _conversations.first.id : null;
    }

    notifyListeners();
  }

  /// Renombra una conversación
  void renameConversation(String conversationId, String newTitle) {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('Conversación no encontrada'),
    );
    conversation.title = newTitle;
    notifyListeners();
  }

  /// Limpia los mensajes de la conversación activa
  void clearActiveConversation() {
    final conversation = activeConversation;
    if (conversation != null) {
      conversation.messages.clear();
      conversation.title = 'Nueva conversación';
      conversation.updatedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Reordena una conversación al inicio
  void _reorderToTop(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index > 0) {
      final conversation = _conversations.removeAt(index);
      _conversations.insert(0, conversation);
    }
  }

  /// Limpia todas las conversaciones
  void clearAll() {
    _conversations.clear();
    _activeConversationId = null;
    notifyListeners();
  }

  /// Carga conversaciones demo para pruebas
  void loadDemoConversations() {
    if (_conversations.isNotEmpty) return;

    final demoConversations = [
      Conversation(
        title: '¿Cómo funciona Flutter?',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        messages: [
          Message(
            role: MessageRole.user,
            content: '¿Cómo funciona Flutter?',
          ),
          Message(
            role: MessageRole.assistant,
            content:
                'Flutter es un framework de UI de código abierto creado por Google. Utiliza el lenguaje Dart y permite crear aplicaciones nativas para móvil, web y escritorio desde una única base de código.',
          ),
        ],
      ),
      Conversation(
        title: 'Explica el patrón Provider',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        messages: [
          Message(
            role: MessageRole.user,
            content: 'Explica el patrón Provider en Flutter',
          ),
          Message(
            role: MessageRole.assistant,
            content:
                'Provider es un wrapper alrededor de InheritedWidget que facilita la gestión de estado en Flutter. Permite compartir datos entre widgets sin pasar props manualmente.',
          ),
        ],
      ),
    ];

    _conversations.addAll(demoConversations);
    _activeConversationId = demoConversations.first.id;
    notifyListeners();
  }
}
