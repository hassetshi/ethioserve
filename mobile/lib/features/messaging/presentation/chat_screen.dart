import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../bookings/presentation/booking_providers.dart';
import '../domain/chat_message.dart';
import 'messaging_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _sendText(String receiverId) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    setState(() => _sending = true);
    try {
      await ref
          .read(messagingRepositoryProvider)
          .sendTextMessage(
            bookingId: widget.bookingId,
            receiverId: receiverId,
            message: text,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage(String receiverId) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _sending = true);
    try {
      final bytes = await picked.readAsBytes();
      final extension = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      await ref
          .read(messagingRepositoryProvider)
          .sendImageMessage(
            bookingId: widget.bookingId,
            receiverId: receiverId,
            bytes: bytes,
            fileExtension: extension,
          );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(bookingStreamProvider(widget.bookingId));
    final currentUserId = ref.watch(currentUserProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('Something went wrong. Please try again.'),
        ),
        data: (booking) {
          if (currentUserId == null) return const SizedBox.shrink();

          final receiverId = currentUserId == booking.customerId
              ? booking.providerUserId
              : booking.customerId;

          if (receiverId == null) {
            return const Center(
              child: Text('Unable to determine the other participant.'),
            );
          }

          final messagesAsync = ref.watch(
            messagesStreamProvider(widget.bookingId),
          );

          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Center(
                    child: Text('Something went wrong. Please try again.'),
                  ),
                  data: (messages) {
                    _markIncomingAsRead(messages, currentUserId);
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Say hello!'),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.senderId == currentUserId,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _sending
                            ? null
                            : () => _sendImage(receiverId),
                        icon: const Icon(Icons.image_outlined),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Message',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendText(receiverId),
                        ),
                      ),
                      IconButton(
                        onPressed: _sending
                            ? null
                            : () => _sendText(receiverId),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _markIncomingAsRead(List<ChatMessage> messages, String currentUserId) {
    for (final message in messages) {
      if (!message.isRead && message.receiverId == currentUserId) {
        ref.read(messagingRepositoryProvider).markAsRead(message.id);
      }
    }
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = isMine
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: message.isImage
            ? _ChatImage(storagePath: message.message ?? '')
            : Text(message.message ?? ''),
      ),
    );
  }
}

class _ChatImage extends ConsumerWidget {
  const _ChatImage({required this.storagePath});

  final String storagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String>(
      future: ref
          .read(messagingRepositoryProvider)
          .getSignedImageUrl(storagePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            width: 120,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            snapshot.data!,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}
