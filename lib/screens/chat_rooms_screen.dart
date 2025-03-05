import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/supabase_service.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';

class ChatRoomsScreen extends StatefulWidget {
  const ChatRoomsScreen({super.key});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final ChatService _chatService = ChatService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _chatRooms = [];
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (!SupabaseService.isAuthenticated) {
        // If not authenticated, prompt to login
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final chatRooms = await _chatService.getChatRooms();
      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chat rooms: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _createChatRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create Chat Room',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: _roomNameController,
          decoration: const InputDecoration(
            labelText: 'Room Name',
            hintText: 'Enter a name for your chat room',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_roomNameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a room name'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              
              try {
                setState(() {
                  _isLoading = true;
                });
                
                final newRoom = await _chatService.createChatRoom(
                  name: _roomNameController.text.trim(),
                );
                
                setState(() {
                  _chatRooms.insert(0, newRoom);
                  _isLoading = false;
                });
                
                _roomNameController.clear();
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating chat room: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat Rooms',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (SupabaseService.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadChatRooms,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: !SupabaseService.isAuthenticated
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Login Required',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You need to be logged in to use the chat feature',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AuthScreen()),
                      );
                    },
                    child: const Text('Login / Sign Up'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
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
                            'No Chat Rooms Yet',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a new chat room to start chatting',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _createChatRoom,
                            child: const Text('Create Chat Room'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChatRooms,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatRooms.length,
                        itemBuilder: (context, index) {
                          final room = _chatRooms[index];
                          final createdBy = room['user']?['full_name'] ?? 'Unknown';
                          
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: UserAvatar(
                                userId: room['created_by'] ?? '',
                                name: createdBy,
                                backgroundColor: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                room['name'],
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('Created by $createdBy'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      roomId: room['id'],
                                      roomName: room['name'],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: SupabaseService.isAuthenticated
          ? FloatingActionButton(
              onPressed: _createChatRoom,
              tooltip: 'Create Chat Room',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
