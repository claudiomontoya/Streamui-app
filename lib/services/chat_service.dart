import 'dart:async';
import 'dart:math';

/// Simula respuestas del bot con streaming token por token
class ChatService {
  static const _responses = [
    "¡Hola! Soy un asistente de chat con streaming. Puedo responder a tus preguntas de forma fluida, mostrando cada palabra mientras se genera la respuesta.",
    "El streaming de mensajes permite una experiencia más natural, similar a como una persona escribiría en tiempo real. Esto mejora significativamente la percepción de velocidad.",
    "Flutter es un framework increíble para crear aplicaciones multiplataforma. Con un solo código base puedes crear apps para iOS, Android, Web y Desktop.",
    "La virtualización de listas es crucial para el rendimiento. En lugar de renderizar todos los elementos, solo renderizamos los visibles más un pequeño buffer.",
    "El auto-scroll inteligente detecta si el usuario está cerca del final. Si está leyendo mensajes anteriores, no lo interrumpimos con scroll automático.",
    "Esta implementación incluye: scroll inteligente, streaming de respuestas, botón flotante para bajar, y paginación inversa para cargar historial antiguo.",
  ];

  final _random = Random();

  /// Genera una respuesta simulada con streaming
  Stream<String> getStreamingResponse(String userMessage) async* {
    // Simular latencia inicial
    await Future.delayed(Duration(milliseconds: 300 + _random.nextInt(500)));

    final response = _responses[_random.nextInt(_responses.length)];
    final words = response.split(' ');

    String accumulated = '';
    for (int i = 0; i < words.length; i++) {
      // Simular velocidad variable de generación
      await Future.delayed(Duration(milliseconds: 30 + _random.nextInt(70)));

      accumulated += (i == 0 ? '' : ' ') + words[i];
      yield accumulated;
    }
  }

  /// Genera mensajes históricos para paginación
  List<Map<String, dynamic>> getHistoricalMessages(int page, int pageSize) {
    final messages = <Map<String, dynamic>>[];
    final baseIndex = page * pageSize;

    for (int i = 0; i < pageSize; i++) {
      final index = baseIndex + i;
      final isUser = index % 2 == 0;

      messages.add({
        'role': isUser ? 'user' : 'assistant',
        'content': isUser
            ? 'Mensaje histórico del usuario #$index'
            : 'Respuesta histórica del asistente #$index. ${_responses[index % _responses.length]}',
        'timestamp': DateTime.now().subtract(Duration(hours: index + 1)),
      });
    }

    return messages.reversed.toList();
  }
}
