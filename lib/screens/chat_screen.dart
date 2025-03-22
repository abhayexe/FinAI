import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const ChatScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  Stream<List<Map<String, dynamic>>>? _messagesStream;
  final Map<String, Color> _userColors = {};

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatService.getChatMessages(widget.roomId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Scroll to bottom after messages load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading messages: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _subscribeToMessages() {
    _messagesStream = _chatService.subscribeToMessages(widget.roomId);
    _messagesStream?.listen((messages) {
      setState(() {
        _messages = messages;
      });

      // Scroll to bottom when new messages arrive
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        roomId: widget.roomId,
        content: messageText,
      );

      // No need to update state manually as we're subscribed to changes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      // Message will be removed from the stream automatically
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Generate a consistent color for a user
  Color _getUserColor(String userId) {
    if (_userColors.containsKey(userId)) {
      return _userColors[userId]!;
    }

    // Current user always gets the primary color
    if (userId == SupabaseService.currentUser?.id) {
      return Theme.of(context).colorScheme.primary;
    }

    // Generate a random but consistent color for this user
    final random = math.Random(userId.hashCode);
    final color = HSLColor.fromAHSL(
      1.0,
      random.nextDouble() * 360, // Random hue
      0.8, // High saturation
      0.5, // Medium lightness for good contrast with white text
    ).toColor();

    _userColors[userId] = color;
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SupabaseService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Text(
              '${_messages.length} messages',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Messages Yet',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Be the first to send a message!',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isCurrentUser =
                              message['user_id'] == currentUserId;
                          final userName =
                              message['user']?['full_name'] ?? 'Unknown';
                          final messageTime =
                              DateTime.parse(message['created_at']);
                          final formattedTime =
                              DateFormat.jm().format(messageTime);
                          final formattedDate =
                              DateFormat.yMMMd().format(messageTime);

                          // Show date header if this is the first message or if the date is different from the previous message
                          final showDateHeader = index == 0 ||
                              DateFormat.yMd().format(DateTime.parse(
                                      _messages[index - 1]['created_at'])) !=
                                  DateFormat.yMd().format(messageTime);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDateHeader)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              Align(
                                alignment: isCurrentUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isCurrentUser) ...[
                                      UserAvatar(
                                        userId: message['user_id'] ?? '',
                                        name: userName,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                                0.7,
                                      ),
                                      child: Card(
                                        color: isCurrentUser
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : _getUserColor(message['user_id']),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 1,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        child: InkWell(
                                          onLongPress: isCurrentUser
                                              ? () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: const Text(
                                                          'Delete Message'),
                                                      content: const Text(
                                                          'Are you sure you want to delete this message?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context),
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                            _deleteMessage(
                                                                message['id']);
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                            foregroundColor:
                                                                Colors.white,
                                                          ),
                                                          child: const Text(
                                                              'Delete'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (!isCurrentUser)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4),
                                                    child: Text(
                                                      userName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withOpacity(0.9),
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  message['content'],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Text(
                                                    formattedTime,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white
                                                          .withOpacity(0.7),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      UserAvatar(
                                        userId: message['user_id'] ?? '',
                                        name: userName,
                                        size: 32,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
