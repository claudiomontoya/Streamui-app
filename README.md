# StreamUI Chat - Flutter

Aplicación de chat en Flutter con manejo inteligente de scroll y streaming de respuestas.

## Características

### Auto-scroll Inteligente
- Solo hace scroll automático cuando el usuario está cerca del final (< 80px)
- Si el usuario está leyendo mensajes anteriores, no lo interrumpe
- Usa un "ancla" al final de la lista para el scroll suave

### Streaming de Respuestas
- Las respuestas del bot se muestran token por token
- Indicador visual de "escribiendo..." durante el streaming
- Auto-scroll continuo durante streaming solo si el usuario está en el bottom

### Botón Flotante "Bajar"
- Aparece cuando el usuario no está en el bottom
- Muestra indicador "Nuevos mensajes" cuando llega contenido nuevo
- Animación suave de aparición/desaparición

### Paginación Inversa (Historial)
- Carga mensajes antiguos al hacer scroll hacia arriba
- Preserva la posición de scroll al insertar mensajes arriba (no "salta")
- Indicador de carga mientras se obtiene el historial

### Virtualización
- Ventana de 200 mensajes máximos en memoria
- `cacheExtent` optimizado para renderizado eficiente
- Animaciones de entrada para nuevos mensajes

## Estructura del Proyecto

```
lib/
├── main.dart                      # Punto de entrada
├── controllers/
│   └── chat_controller.dart       # Lógica de chat y scroll
├── models/
│   └── message.dart               # Modelo de mensaje
├── screens/
│   └── chat_screen.dart           # Pantalla principal
├── services/
│   └── chat_service.dart          # Simulación de API/streaming
├── theme/
│   └── app_theme.dart             # Tema claro/oscuro
└── widgets/
    ├── chat_input.dart            # Input de mensaje
    ├── message_bubble.dart        # Burbuja de mensaje
    ├── message_list.dart          # Lista virtualizada
    └── scroll_to_bottom_button.dart # Botón flotante
```

## Cómo Ejecutar

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en modo release
flutter run --release
```

## Patrones Implementados

### Detección de "En el Bottom"
```dart
bool _checkIfAtBottom() {
  final position = scrollController.position;
  final distanceFromBottom = position.maxScrollExtent - position.pixels;
  return distanceFromBottom < 80.0; // Umbral de 80px
}
```

### Preservar Posición en Paginación
```dart
// Guardar altura antes de insertar
final previousScrollHeight = scrollController.position.maxScrollExtent;

// Insertar mensajes al inicio
_messages.insertAll(0, newMessages);

// Restaurar posición
WidgetsBinding.instance.addPostFrameCallback((_) {
  final newScrollHeight = scrollController.position.maxScrollExtent;
  final scrollDiff = newScrollHeight - previousScrollHeight;
  scrollController.jumpTo(scrollController.position.pixels + scrollDiff);
});
```

### Auto-scroll Condicional
```dart
void _autoScrollIfAtBottom() {
  if (_isAtBottom) {
    scrollToBottom();
  } else {
    _hasNewMessages = true; // Mostrar indicador
  }
}
```

## Dependencias

- `provider` - State management
- `uuid` - Generación de IDs únicos
- `cupertino_icons` - Iconos iOS

## Licencia

MIT
