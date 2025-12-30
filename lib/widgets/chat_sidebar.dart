import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/conversation_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/conversation.dart';

/// Sidebar con historial de conversaciones
class ChatSidebar extends StatelessWidget {
  final VoidCallback? onConversationSelected;

  const ChatSidebar({super.key, this.onConversationSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 300,
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          // Header con nuevo chat
          _buildHeader(context, theme),

          // Lista de conversaciones
          Expanded(
            child: _buildConversationList(context, theme),
          ),

          // Footer con usuario y configuración
          _buildFooter(context, theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.stream,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'StreamUI Chat',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botón nuevo chat
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _createNewChat(context),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Nuevo chat'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(BuildContext context, ThemeData theme) {
    return Consumer<ConversationController>(
      builder: (context, controller, _) {
        final conversations = controller.conversations;

        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin conversaciones',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia un nuevo chat',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          );
        }

        // Agrupar conversaciones por fecha
        final grouped = _groupConversations(conversations);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final group = grouped[index];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta de fecha
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    group.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                // Conversaciones del grupo
                ...group.conversations.map(
                  (conv) => _ConversationTile(
                    conversation: conv,
                    isActive: conv.id == controller.activeConversationId,
                    onTap: () {
                      controller.setActiveConversation(conv.id);
                      onConversationSelected?.call();
                    },
                    onDelete: () => _deleteConversation(context, conv),
                    onRename: () => _renameConversation(context, conv),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Column(
        children: [
          // Selector de tema
          Consumer<ThemeController>(
            builder: (context, themeController, _) {
              return ListTile(
                dense: true,
                leading: Icon(
                  themeController.themeIcon,
                  size: 20,
                ),
                title: const Text('Tema'),
                subtitle: Text(
                  themeController.themeLabel,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onTap: () => _showThemeSelector(context),
              );
            },
          ),
          const SizedBox(height: 4),

          // Usuario y logout
          Consumer<AuthController>(
            builder: (context, authController, _) {
              final user = authController.currentUser;
              if (user == null) return const SizedBox.shrink();

              return ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  user.email,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => _logout(context),
                  tooltip: 'Cerrar sesión',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _createNewChat(BuildContext context) {
    context.read<ConversationController>().createNewConversation();
    onConversationSelected?.call();
  }

  void _deleteConversation(BuildContext context, Conversation conv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar conversación'),
        content: Text('¿Eliminar "${conv.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<ConversationController>().deleteConversation(conv.id);
              Navigator.pop(ctx);
            },
            child: Text(
              'Eliminar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _renameConversation(BuildContext context, Conversation conv) {
    final controller = TextEditingController(text: conv.title);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Nuevo nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<ConversationController>().renameConversation(
                      conv.id,
                      controller.text.trim(),
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Consumer<ThemeController>(
        builder: (context, controller, _) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Seleccionar tema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _ThemeOption(
                  icon: Icons.brightness_auto,
                  title: 'Automático',
                  subtitle: 'Sigue la configuración del sistema',
                  isSelected: controller.isSystemMode,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.system);
                    Navigator.pop(ctx);
                  },
                ),
                _ThemeOption(
                  icon: Icons.light_mode,
                  title: 'Claro',
                  subtitle: 'Tema claro siempre',
                  isSelected: controller.isLightMode,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.light);
                    Navigator.pop(ctx);
                  },
                ),
                _ThemeOption(
                  icon: Icons.dark_mode,
                  title: 'Oscuro',
                  subtitle: 'Tema oscuro siempre',
                  isSelected: controller.isDarkMode,
                  onTap: () {
                    controller.setThemeMode(ThemeMode.dark);
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthController>().logout();
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  List<_ConversationGroup> _groupConversations(List<Conversation> conversations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final groups = <String, List<Conversation>>{
      'Hoy': [],
      'Ayer': [],
      'Últimos 7 días': [],
      'Anteriores': [],
    };

    for (final conv in conversations) {
      final date = DateTime(
        conv.updatedAt.year,
        conv.updatedAt.month,
        conv.updatedAt.day,
      );

      if (date == today) {
        groups['Hoy']!.add(conv);
      } else if (date == yesterday) {
        groups['Ayer']!.add(conv);
      } else if (date.isAfter(lastWeek)) {
        groups['Últimos 7 días']!.add(conv);
      } else {
        groups['Anteriores']!.add(conv);
      }
    }

    return groups.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _ConversationGroup(label: e.key, conversations: e.value))
        .toList();
  }
}

class _ConversationGroup {
  final String label;
  final List<Conversation> conversations;

  _ConversationGroup({required this.label, required this.conversations});
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isActive
            ? theme.colorScheme.primaryContainer.withOpacity(0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'rename',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Renombrar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Eliminar',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'rename') {
                      onRename();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
