import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String applicationId;
  final String jobId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;

  ChatModel({
    required this.chatId,
    required this.applicationId,
    required this.jobId,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      chatId: map['chat_id'] ?? '',
      applicationId: map['application_id'] ?? '',
      jobId: map['job_id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['last_message'] ?? '',
      lastMessageTime:
          (map['last_message_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(map['unread_count'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'application_id': applicationId,
      'job_id': jobId,
      'participants': participants,
      'last_message': lastMessage,
      'last_message_time': Timestamp.fromDate(lastMessageTime),
      'unread_count': unreadCount,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere((id) => id != currentUserId,
        orElse: () => '');
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String receiverId;
  final String text;
  final String attachmentUrl;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    this.text = '',
    this.attachmentUrl = '',
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['message_id'] ?? '',
      senderId: map['sender_id'] ?? '',
      receiverId: map['receiver_id'] ?? '',
      text: map['text'] ?? '',
      attachmentUrl: map['attachment_url'] ?? '',
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message_id': messageId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'text': text,
      'attachment_url': attachmentUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'is_read': isRead,
    };
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Now';
  }
}
