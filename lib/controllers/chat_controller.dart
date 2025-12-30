import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/attachment.dart';
import '../services/chat_service.dart';
import 'conversation_controller.dart';

/// Controlador principal del chat con scroll inteligente y streaming
class ChatController extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ScrollController scrollController = ScrollController();
  ConversationController? _conversationController;

  // Estado de mensajes
  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);

  // Attachments pendientes
  List<Attachment> _pendingAttachments = [];
  List<Attachment> get pendingAttachments => List.unmodifiable(_pendingAttachments);

  // Estado de scroll
  bool _isAtBottom = true;
  bool get isAtBottom => _isAtBottom;

  bool _hasNewMessages = false;
  bool get hasNewMessages => _hasNewMessages;

  // Estado de streaming
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  StreamSubscription<String>? _streamSubscription;

  // Paginación
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  bool _hasMoreHistory = true;
  bool get hasMoreHistory => _hasMoreHistory;

  int _historyPage = 0;
  static const int _pageSize = 20;

  // Umbral para considerar "cerca del final" (en pixels)
  static const double _bottomThreshold = 80.0;

  // Ventana de mensajes visibles (para rendimiento)
  static const int _maxVisibleMessages = 200;

  ChatController() {
    scrollController.addListener(_onScroll);
  }

  /// Conecta con el controlador de conversaciones
  void setConversationController(ConversationController controller) {
    _conversationController = controller;
  }

  /// Carga los mensajes de la conversación activa
  void loadActiveConversation() {
    if (_conversationController == null) return;

    _messages.clear();
    final activeMessages = _conversationController!.getActiveMessages();
    _messages.addAll(activeMessages);
    _historyPage = 0;
    _hasMoreHistory = false; // Por ahora sin historial en conversaciones existentes
    _isAtBottom = true;
    _hasNewMessages = false;

    notifyListeners();

    // Scroll al final después de cargar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom(animated: false);
    });
  }

  /// Listener de scroll para detectar posición
  void _onScroll() {
    final isNowAtBottom = _checkIfAtBottom();

    if (isNowAtBottom != _isAtBottom) {
      _isAtBottom = isNowAtBottom;

      // Si el usuario bajó al final, limpiar indicador de nuevos mensajes
      if (_isAtBottom) {
        _hasNewMessages = false;
      }

      notifyListeners();
    }

    // Detectar scroll hacia arriba para cargar historial
    if (scrollController.position.pixels <= 100 &&
        !_isLoadingHistory &&
        _hasMoreHistory) {
      _loadMoreHistory();
    }
  }

  /// Verifica si el scroll está cerca del final
  bool _checkIfAtBottom() {
    if (!scrollController.hasClients) return true;

    final position = scrollController.position;
    final distanceFromBottom =
        position.maxScrollExtent - position.pixels;

    return distanceFromBottom < _bottomThreshold;
  }

  /// Scroll al final con animación
  void scrollToBottom({bool animated = true}) {
    if (!scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;

      if (animated) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }

      _isAtBottom = true;
      _hasNewMessages = false;
      notifyListeners();
    });
  }

  /// Auto-scroll inteligente: solo si está en el bottom
  void _autoScrollIfAtBottom() {
    if (_isAtBottom) {
      scrollToBottom();
    } else {
      // Marcar que hay nuevos mensajes si no está en el bottom
      _hasNewMessages = true;
      notifyListeners();
    }
  }

  /// Envía un mensaje del usuario con attachments opcionales
  Future<void> sendMessage(String content, [List<Attachment>? attachments]) async {
    if ((content.trim().isEmpty && (attachments?.isEmpty ?? true)) || _isStreaming) return;

    // Construir contenido con información de archivos adjuntos
    String fullContent = content.trim();
    if (attachments != null && attachments.isNotEmpty) {
      final attachmentInfo = attachments
          .map((a) => '[Archivo: ${a.name}]')
          .join(' ');
      fullContent = attachmentInfo + (fullContent.isNotEmpty ? '\n$fullContent' : '');
    }

    // Agregar mensaje del usuario
    final userMessage = Message(
      role: MessageRole.user,
      content: fullContent,
      status: MessageStatus.complete,
    );
    _addMessage(userMessage);

    // Sincronizar con conversación
    _conversationController?.addMessageToActive(userMessage);

    // Auto-scroll después de enviar
    scrollToBottom();

    // Iniciar respuesta del bot con streaming
    await _startBotResponse(fullContent);
  }

  /// Inicia la respuesta del bot con streaming
  Future<void> _startBotResponse(String userMessage) async {
    _isStreaming = true;
    notifyListeners();

    // Crear mensaje vacío del bot
    final botMessage = Message(
      role: MessageRole.assistant,
      content: '',
      status: MessageStatus.streaming,
    );
    _addMessage(botMessage);
    _conversationController?.addMessageToActive(botMessage);
    _autoScrollIfAtBottom();

    // Escuchar stream de respuesta
    _streamSubscription = _chatService
        .getStreamingResponse(userMessage)
        .listen(
      (partialContent) {
        _updateLastBotMessage(partialContent);
        _conversationController?.updateLastMessageInActive(partialContent);
        _autoScrollIfAtBottom();
      },
      onDone: () {
        _finishStreaming();
      },
      onError: (error) {
        _handleStreamError(error);
      },
    );
  }

  /// Actualiza el último mensaje del bot durante streaming
  void _updateLastBotMessage(String content) {
    if (_messages.isEmpty) return;

    final lastIndex = _messages.length - 1;
    final lastMessage = _messages[lastIndex];

    if (lastMessage.isAssistant && lastMessage.isStreaming) {
      _messages[lastIndex] = lastMessage.copyWith(content: content);
      notifyListeners();
    }
  }

  /// Finaliza el streaming
  void _finishStreaming() {
    _isStreaming = false;
    _streamSubscription = null;

    if (_messages.isNotEmpty) {
      final lastIndex = _messages.length - 1;
      final lastMessage = _messages[lastIndex];

      if (lastMessage.isAssistant) {
        _messages[lastIndex] = lastMessage.copyWith(
          status: MessageStatus.complete,
        );
        _conversationController?.updateLastMessageInActive(
          lastMessage.content,
          status: MessageStatus.complete,
        );
      }
    }

    notifyListeners();
  }

  /// Maneja errores de streaming
  void _handleStreamError(dynamic error) {
    _isStreaming = false;
    _streamSubscription = null;

    if (_messages.isNotEmpty) {
      final lastIndex = _messages.length - 1;
      final lastMessage = _messages[lastIndex];

      if (lastMessage.isAssistant) {
        _messages[lastIndex] = lastMessage.copyWith(
          content: 'Error: No se pudo obtener la respuesta.',
          status: MessageStatus.error,
        );
      }
    }

    notifyListeners();
  }

  /// Agrega un mensaje aplicando ventana de mensajes
  void _addMessage(Message message) {
    _messages.add(message);

    // Aplicar ventana: mantener solo los últimos N mensajes en memoria
    if (_messages.length > _maxVisibleMessages) {
      _messages.removeAt(0);
      _hasMoreHistory = true;
    }

    notifyListeners();
  }

  /// Carga historial antiguo (paginación inversa)
  Future<void> _loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    // Guardar posición actual para restaurar después
    final previousScrollHeight = scrollController.position.maxScrollExtent;

    await Future.delayed(const Duration(milliseconds: 500));

    final historicalMessages = _chatService.getHistoricalMessages(
      _historyPage,
      _pageSize,
    );

    if (historicalMessages.isEmpty) {
      _hasMoreHistory = false;
    } else {
      // Insertar mensajes al inicio
      final newMessages = historicalMessages.map((data) => Message(
            role: data['role'] == 'user'
                ? MessageRole.user
                : MessageRole.assistant,
            content: data['content'],
            timestamp: data['timestamp'],
          )).toList();

      _messages.insertAll(0, newMessages);
      _historyPage++;

      // Restaurar posición de scroll para que no "salte"
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final newScrollHeight = scrollController.position.maxScrollExtent;
          final scrollDiff = newScrollHeight - previousScrollHeight;
          scrollController.jumpTo(scrollController.position.pixels + scrollDiff);
        }
      });
    }

    _isLoadingHistory = false;
    notifyListeners();
  }

  /// Cancela streaming en curso
  void cancelStreaming() {
    _streamSubscription?.cancel();
    _finishStreaming();
  }

  /// Limpia el chat
  void clearChat() {
    cancelStreaming();
    _messages.clear();
    _historyPage = 0;
    _hasMoreHistory = true;
    _hasNewMessages = false;
    _isAtBottom = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
