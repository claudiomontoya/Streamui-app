# StreamUI Chat - Flutter

Aplicación de chat completa en Flutter con manejo inteligente de scroll, streaming de respuestas, y múltiples funcionalidades.

## Características

### Login Demo
- Pantalla de login con validación
- Acceso rápido con usuario demo
- Persistencia de sesión con SharedPreferences
- Credenciales: cualquier email + contraseña "demo"

### Sidebar con Historial
- Lista de conversaciones agrupadas por fecha (Hoy, Ayer, Últimos 7 días)
- Botón "Nuevo chat" para crear conversaciones
- Renombrar y eliminar conversaciones
- Diseño responsivo: drawer en móvil, fijo en tablet/desktop

### Cambio de Tema
- Tres modos: Claro, Oscuro, Automático (sistema)
- Botón en AppBar para cambio rápido
- Selector completo en Sidebar
- Persistencia de preferencia

### Adjuntar Archivos
- Soporte para imágenes, documentos, audio, video
- Vista previa de archivos seleccionados
- Límite de 10MB por archivo
- Chips removibles antes de enviar

### Dictado por Voz
- Speech-to-Text integrado
- Indicador visual de grabación
- Soporte para español y otros idiomas
- Transcripción en tiempo real

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
├── main.dart                          # Punto de entrada con providers
├── controllers/
│   ├── auth_controller.dart           # Autenticación
│   ├── chat_controller.dart           # Lógica de chat y scroll
│   ├── conversation_controller.dart   # Gestión de conversaciones
│   └── theme_controller.dart          # Control de tema
├── models/
│   ├── attachment.dart                # Modelo de archivo adjunto
│   ├── conversation.dart              # Modelo de conversación
│   ├── message.dart                   # Modelo de mensaje
│   └── user.dart                      # Modelo de usuario
├── screens/
│   ├── chat_screen.dart               # Pantalla principal con sidebar
│   └── login_screen.dart              # Pantalla de login
├── services/
│   ├── chat_service.dart              # Simulación de API/streaming
│   ├── file_service.dart              # Manejo de archivos
│   └── speech_service.dart            # Reconocimiento de voz
├── theme/
│   └── app_theme.dart                 # Tema claro/oscuro Material 3
└── widgets/
    ├── chat_input.dart                # Input con adjuntos y micrófono
    ├── chat_sidebar.dart              # Sidebar de conversaciones
    ├── message_bubble.dart            # Burbuja de mensaje
    ├── message_list.dart              # Lista virtualizada
    └── scroll_to_bottom_button.dart   # Botón flotante
```

## Cómo Ejecutar

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo debug
flutter run

# Ejecutar en web
flutter run -d chrome

# Ejecutar en modo release
flutter run --release
```

## Permisos Requeridos

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Se requiere acceso al micrófono para dictado por voz</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Se requiere reconocimiento de voz para transcribir mensajes</string>
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
- `shared_preferences` - Persistencia local
- `file_picker` - Selección de archivos
- `speech_to_text` - Reconocimiento de voz
- `permission_handler` - Manejo de permisos
- `path` - Utilidades de rutas
- `mime` - Detección de tipos MIME
- `cupertino_icons` - Iconos iOS

## Licencia

MIT
