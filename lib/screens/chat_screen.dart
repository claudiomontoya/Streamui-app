import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_list.dart';
import '../widgets/scroll_to_bottom_button.dart';

/// Pantalla principal del chat
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: const _ChatScreenContent(),
    );
  }
}

class _ChatScreenContent extends StatelessWidget {
  const _ChatScreenContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(context),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'StreamUI Chat',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer<ChatController>(
                builder: (context, controller, _) {
                  return Text(
                    controller.isStreaming
                        ? 'Escribiendo...'
                        : 'En línea',
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
        ],
      ),
      actions: [
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
                }
              },
              itemBuilder: (context) => [
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
                      const Text('Limpiar chat'),
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
          onSend: controller.sendMessage,
          enabled: !controller.isStreaming,
        );
      },
    );
  }

  void _showClearConfirmation(
      BuildContext context, ChatController controller) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar chat'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todos los mensajes?',
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
