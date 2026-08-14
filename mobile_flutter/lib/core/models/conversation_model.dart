class MessageModel {
  final int id;
  final int conversationId;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      conversationId: json['conversationId'] ?? 0,
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'] ?? 'Anonyme',
      senderAvatar: json['senderAvatar'],
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ConversationModel {
  final int id;
  final String name;
  final String type; // PRIVATE, GROUP, BIRTHDAY
  final int? birthdayId;
  final List<String> members;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.name,
    required this.type,
    this.birthdayId,
    this.members = const [],
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get isPrivate => type == 'PRIVATE';
  bool get isGroup => type == 'GROUP';
  bool get isBirthday => type == 'BIRTHDAY';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Chat',
      type: json['type'] ?? 'PRIVATE',
      birthdayId: json['birthdayId'],
      members: json['members'] != null
          ? List<String>.from(json['members'])
          : const [],
      lastMessage: json['lastMessage'],
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  ConversationModel copyWith({
    int? id,
    String? name,
    String? type,
    int? birthdayId,
    List<String>? members,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      birthdayId: birthdayId ?? this.birthdayId,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}
