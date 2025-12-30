import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/attachment.dart';
import '../services/file_service.dart';
import '../services/speech_service.dart';

/// Campo de entrada de texto para el chat con adjuntos y voz
class ChatInput extends StatefulWidget {
  final Function(String, List<Attachment>) onSend;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.onSend,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _fileService = FileService();
  late SpeechService _speechService;

  bool _hasText = false;
  List<Attachment> _attachments = [];
  bool _isRecording = false;
  late AnimationController _micAnimationController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _speechService = SpeechService();
    _speechService.onResult = _onSpeechResult;
    _speechService.onError = _onSpeechError;

    _micAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onSpeechResult(String text, bool isFinal) {
    setState(() {
      _controller.text = text;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    });

    if (isFinal) {
      setState(() => _isRecording = false);
    }
  }

  void _onSpeechError(String error) {
    setState(() => _isRecording = false);
    _showSnackBar(error, isError: true);
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if ((text.isNotEmpty || _attachments.isNotEmpty) && widget.enabled) {
      widget.onSend(text, List.from(_attachments));
      _controller.clear();
      setState(() {
        _attachments = [];
        _hasText = false;
      });
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleAttachment() async {
    try {
      final attachments = await _fileService.pickFiles();
      if (attachments.isNotEmpty) {
        setState(() {
          _attachments.addAll(attachments);
          _hasText = true;
        });
      }
    } catch (e) {
      _showSnackBar(e.toString(), isError: true);
    }
  }

  Future<void> _handleVoiceInput() async {
    if (_isRecording) {
      await _speechService.stopListening();
      setState(() => _isRecording = false);
      return;
    }

    final available = await _speechService.initialize();
    if (!available) {
      _showSnackBar(
        'Reconocimiento de voz no disponible',
        isError: true,
      );
      return;
    }

    setState(() => _isRecording = true);
    await _speechService.startListening();
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
      _hasText = _controller.text.trim().isNotEmpty || _attachments.isNotEmpty;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _speechService.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Archivos adjuntos
            if (_attachments.isNotEmpty) _buildAttachmentsList(theme),

            // Input principal
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Botón adjuntar
                  _buildIconButton(
                    icon: Icons.attach_file,
                    onPressed: widget.enabled ? _handleAttachment : null,
                    theme: theme,
                  ),
                  const SizedBox(width: 8),

                  // Campo de texto
                  Expanded(child: _buildTextField(theme)),
                  const SizedBox(width: 8),

                  // Botón micrófono
                  _buildMicButton(theme),
                  const SizedBox(width: 8),

                  // Botón enviar
                  _buildSendButton(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsList(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _attachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final attachment = _attachments[index];
          return _AttachmentChip(
            attachment: attachment,
            onRemove: () => _removeAttachment(index),
          );
        },
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            _handleSubmit();
          }
        },
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: widget.enabled && !_isRecording,
          maxLines: null,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: _isRecording
                ? 'Escuchando...'
                : widget.enabled
                    ? 'Escribe un mensaje...'
                    : 'Esperando respuesta...',
            hintStyle: TextStyle(
              color: _isRecording
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: onPressed != null
                ? theme.colorScheme.onSurface.withOpacity(0.7)
                : theme.colorScheme.onSurface.withOpacity(0.3),
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(ThemeData theme) {
    return AnimatedBuilder(
      animation: _micAnimationController,
      builder: (context, child) {
        return Material(
          color: _isRecording
              ? Color.lerp(
                  theme.colorScheme.error,
                  theme.colorScheme.errorContainer,
                  _micAnimationController.value,
                )
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.enabled ? _handleVoiceInput : null,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording
                    ? Colors.white
                    : widget.enabled
                        ? theme.colorScheme.onSurface.withOpacity(0.7)
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final canSend = _hasText && widget.enabled;

    return Material(
      color: canSend
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: canSend ? _handleSubmit : null,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            Icons.send_rounded,
            color: canSend
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.3),
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Chip de archivo adjunto
class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;

  const _AttachmentChip({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(attachment.type),
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  attachment.formattedSize,
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return Icons.image;
      case AttachmentType.video:
        return Icons.video_file;
      case AttachmentType.audio:
        return Icons.audio_file;
      case AttachmentType.document:
        return Icons.description;
      case AttachmentType.other:
        return Icons.insert_drive_file;
    }
  }
}
