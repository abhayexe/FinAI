import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<ChatRoom> _chatRooms = [];
  Map<String, List<ChatMessage>> _chatMessages = {};
  bool _isLoading = false;
  String? _currentRoomId;

  List<ChatRoom> get chatRooms => _chatRooms;
  List<ChatMessage> get currentRoomMessages => 
      _currentRoomId != null ? _chatMessages[_currentRoomId!] ?? [] : [];
  bool get isLoading => _isLoading;
  String? get currentRoomId => _currentRoomId;

  void setCurrentRoom(String roomId) {
    _currentRoomId = roomId;
    notifyListeners();
  }

  Future<void> loadChatRooms() async {
    _isLoading = true;
    notifyListeners();

    try {
      final roomsData = await _chatService.getChatRooms();
      _chatRooms = roomsData.map((room) => ChatRoom.fromJson(room)).toList();
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String roomId) async {
    if (_chatMessages.containsKey(roomId) && _chatMessages[roomId]!.isNotEmpty) {
      return; // Messages already loaded
    }

    _isLoading = true;
    notifyListeners();

    try {
      final messagesData = await _chatService.getChatMessages(roomId);
      _chatMessages[roomId] = messagesData.map((msg) => ChatMessage.fromJson(msg)).toList();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ChatRoom?> createChatRoom(String name) async {
    try {
      final roomData = await _chatService.createChatRoom(name: name);
      final newRoom = ChatRoom.fromJson(roomData);
      _chatRooms.insert(0, newRoom);
      notifyListeners();
      return newRoom;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      return null;
    }
  }

  Future<ChatMessage?> sendMessage(String content) async {
    if (_currentRoomId == null) return null;

    try {
      final messageData = await _chatService.sendMessage(
        roomId: _currentRoomId!,
        content: content,
      );
      
      final newMessage = ChatMessage.fromJson(messageData);
      
      if (!_chatMessages.containsKey(_currentRoomId!)) {
        _chatMessages[_currentRoomId!] = [];
      }
      
      _chatMessages[_currentRoomId!]!.add(newMessage);
      notifyListeners();
      
      return newMessage;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return null;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    if (_currentRoomId == null) return false;

    try {
      await _chatService.deleteMessage(messageId);
      
      // Remove the message from the local list
      _chatMessages[_currentRoomId!] = _chatMessages[_currentRoomId!]!
          .where((msg) => msg.id != messageId)
          .toList();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  void updateMessagesFromStream(List<Map<String, dynamic>> messages, String roomId) {
    if (!_chatMessages.containsKey(roomId)) {
      _chatMessages[roomId] = [];
    }
    
    _chatMessages[roomId] = messages.map((msg) => ChatMessage.fromJson(msg)).toList();
    notifyListeners();
  }

  void clearMessages(String roomId) {
    _chatMessages.remove(roomId);
    notifyListeners();
  }

  void clearAllData() {
    _chatRooms = [];
    _chatMessages = {};
    _currentRoomId = null;
    notifyListeners();
  }
}
