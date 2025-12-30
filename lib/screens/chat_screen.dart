import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import '../controllers/conversation_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_sidebar.dart';
import '../widgets/message_list.dart';
import '../widgets/scroll_to_bottom_button.dart';

/// Pantalla principal del chat con sidebar
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ChatController _chatController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _chatController = ChatController();

    // Conectar con el controlador de conversaciones después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final conversationController = context.read<ConversationController>();
      _chatController.setConversationController(conversationController);

      // Cargar conversaciones demo si está vacío
      if (!conversationController.hasConversations) {
        conversationController.loadDemoConversations();
      }

      // Cargar mensajes de la conversación activa
      _chatController.loadActiveConversation();

      // Escuchar cambios en la conversación activa
      conversationController.addListener(_onConversationChanged);
    });
  }

  void _onConversationChanged() {
    _chatController.loadActiveConversation();
  }

  @override
  void dispose() {
    context.read<ConversationController>().removeListener(_onConversationChanged);
    _chatController.dispose();
    super.dispose();
  }

  void _closeSidebar() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatController,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Diseño responsivo: sidebar fijo en pantallas grandes
          final isWideScreen = constraints.maxWidth >= 768;

          if (isWideScreen) {
            return _buildWideLayout(context);
          } else {
            return _buildNarrowLayout(context);
          }
        },
      ),
    );
  }

  /// Layout para pantallas anchas (tablet/desktop)
  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar fijo
          ChatSidebar(
            onConversationSelected: () {},
          ),
          // Separador vertical
          VerticalDivider(
            width: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
          // Área de chat
          Expanded(
            child: _ChatArea(scaffoldKey: _scaffoldKey),
          ),
        ],
      ),
    );
  }

  /// Layout para pantallas angostas (móvil)
  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: ChatSidebar(
        onConversationSelected: _closeSidebar,
      ),
      body: _ChatArea(
        scaffoldKey: _scaffoldKey,
        showMenuButton: true,
      ),
    );
  }
}

/// Área principal del chat
class _ChatArea extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final bool showMenuButton;

  const _ChatArea({
    required this.scaffoldKey,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context, theme),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Lista de mensajes con botón flotante
            Expanded(
              child: Stack(
                children: [
                  const MessageList(),
                  _buildScrollToBottomButton(context),
                ],
              ),
            ),
            // Input de mensaje
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ThemeData theme) {
    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: showMenuButton
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                scaffoldKey.currentState?.openDrawer();
              },
            )
          : null,
      title: Consumer<ConversationController>(
        builder: (context, convController, _) {
          final activeConv = convController.activeConversation;

          return Row(
            children: [
              if (!showMenuButton) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.stream,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeConv?.title ?? 'StreamUI Chat',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Consumer<ChatController>(
                      builder: (context, controller, _) {
                        return Text(
                          controller.isStreaming ? 'Escribiendo...' : 'En línea',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: controller.isStreaming
                                ? theme.colorScheme.primary
                                : Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Botón de tema
        Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return IconButton(
              icon: Icon(themeController.themeIcon),
              onPressed: () => themeController.cycleTheme(),
              tooltip: 'Cambiar tema: ${themeController.themeLabel}',
            );
          },
        ),
        // Menú
        Consumer<ChatController>(
          builder: (context, controller, _) {
            return PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: theme.colorScheme.onSurface,
              ),
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearConfirmation(context, controller);
                } else if (value == 'new') {
                  context.read<ConversationController>().createNewConversation();
                  controller.clearChat();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'new',
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 12),
                      Text('Nuevo chat'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Limpiar chat',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildScrollToBottomButton(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final showButton = !controller.isAtBottom || controller.hasNewMessages;

        return Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: ScrollToBottomButton(
              visible: showButton,
              hasNewMessages: controller.hasNewMessages,
              onPressed: () => controller.scrollToBottom(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        return ChatInput(
          onSend: (text, attachments) {
            controller.sendMessage(text, attachments);
          },
          enabled: !controller.isStreaming,
        );
      },
    );
  }

  void _showClearConfirmation(BuildContext context, ChatController controller) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar chat'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los mensajes de esta conversación?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.clearChat();
              context.read<ConversationController>().clearActiveConversation();
              Navigator.pop(context);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
