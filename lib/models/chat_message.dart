class ChatMessage {
  final String id;
  final String roomId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic>? user;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.user,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      userId: json['user_id'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'user': user,
    };
  }

  bool get isDeleted => content == '[This message was deleted]';
}

class ChatRoom {
  final String id;
  final String name;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? user;

  ChatRoom({
    required this.id,
    required this.name,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user,
    };
  }
}
