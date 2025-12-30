import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación preferida
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const StreamUIApp());
}

/// Aplicación principal de StreamUI Chat
///
/// Características implementadas:
/// - Auto-scroll inteligente (solo cuando está cerca del final)
/// - Streaming de respuestas token por token
/// - Botón flotante "bajar" cuando hay nuevos mensajes
/// - Paginación inversa para cargar historial
/// - Virtualización de lista para rendimiento
/// - Animaciones suaves de entrada de mensajes
class StreamUIApp extends StatelessWidget {
  const StreamUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamUI Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const ChatScreen(),
    );
  }
}
