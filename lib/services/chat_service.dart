import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  
  factory ChatService() {
    return _instance;
  }
  
  ChatService._internal();
  
  // Get reference to the Supabase client
  SupabaseClient get _client => SupabaseService.client;
  
  // Create a new chat room
  Future<Map<String, dynamic>> createChatRoom({required String name}) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      
      final response = await _client
          .from('chat_rooms')
          .insert({
            'name': name,
            'created_by': userId, // This can be null, which is fine for the database
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error creating chat room: $e');
      rethrow;
    }
  }
  
  // Get all chat rooms
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      final response = await _client
          .from('chat_rooms')
          .select('*, user:profiles!chat_rooms_created_by_fkey(full_name)')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting chat rooms: $e');
      return [];
    }
  }
  
  // Get messages for a specific chat room
  Future<List<Map<String, dynamic>>> getChatMessages(String roomId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('*, user:profiles!chat_messages_user_id_fkey(full_name)')
          .eq('room_id', roomId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting chat messages: $e');
      return [];
    }
  }
  
  // Send a message to a chat room
  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await _client
          .from('chat_messages')
          .insert({
            'room_id': roomId,
            'user_id': userId,
            'content': content,
          })
          .select('*, user:profiles!chat_messages_user_id_fkey(full_name)')
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }
  
  // Subscribe to new messages in a chat room
  Stream<List<Map<String, dynamic>>> subscribeToMessages(String roomId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }
  
  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _client
          .from('chat_messages')
          .delete()
          .eq('id', messageId)
          .eq('user_id', userId); // Now using non-nullable userId
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }
  
  // Join a chat room (for future use if implementing private rooms)
  Future<void> joinChatRoom(String roomId) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _client
          .from('chat_room_members')
          .insert({
            'room_id': roomId,
            'user_id': userId,
          });
    } catch (e) {
      debugPrint('Error joining chat room: $e');
      rethrow;
    }
  }
}
