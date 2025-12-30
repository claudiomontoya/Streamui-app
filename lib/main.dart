import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/conversation_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/chat_screen.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientación preferida
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const StreamUIApp());
}

/// Aplicación principal de StreamUI Chat
///
/// Características implementadas:
/// - Login demo con persistencia de sesión
/// - Auto-scroll inteligente (solo cuando está cerca del final)
/// - Streaming de respuestas token por token
/// - Botón flotante "bajar" cuando hay nuevos mensajes
/// - Sidebar con historial de conversaciones
/// - Cambio de tema claro/oscuro/automático
/// - Adjuntar archivos
/// - Dictado por voz (Speech to Text)
/// - Paginación inversa para cargar historial
/// - Virtualización de lista para rendimiento
/// - Diseño responsivo (móvil/tablet/desktop)
class StreamUIApp extends StatelessWidget {
  const StreamUIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Controlador de autenticación
        ChangeNotifierProvider(create: (_) => AuthController()),
        // Controlador de tema
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Controlador de conversaciones
        ChangeNotifierProvider(create: (_) => ConversationController()),
      ],
      child: const _AppWithTheme(),
    );
  }
}

/// Widget que aplica el tema y maneja la navegación según autenticación
class _AppWithTheme extends StatefulWidget {
  const _AppWithTheme();

  @override
  State<_AppWithTheme> createState() => _AppWithThemeState();
}

class _AppWithThemeState extends State<_AppWithTheme> {
  @override
  void initState() {
    super.initState();
    // Inicializar controladores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().initialize();
      context.read<ThemeController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeController, AuthController>(
      builder: (context, themeController, authController, _) {
        return MaterialApp(
          title: 'StreamUI Chat',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          home: _buildHome(authController),
        );
      },
    );
  }

  Widget _buildHome(AuthController authController) {
    // Mostrar loading mientras se inicializa
    if (!authController.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Mostrar login o chat según autenticación
    if (authController.isAuthenticated) {
      return const ChatScreen();
    } else {
      return const LoginScreen();
    }
  }
}
