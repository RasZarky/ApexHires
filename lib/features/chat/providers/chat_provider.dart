import 'package:flutter/material.dart';
import 'package:apex_hires/models/chat_model.dart';
import 'package:apex_hires/services/firestore_service.dart';

class ChatProvider extends ChangeNotifier {
  FirestoreService? _firestoreServiceRef;
  FirestoreService get _firestoreService =>
      _firestoreServiceRef ??= FirestoreService();

  String? _error;

  String? get error => _error;

  // Get chats for user
  Stream<List<ChatModel>> getChatsForUser(String userId) {
    return _firestoreService.getChatsForUser(userId);
  }

  // Get or create chat
  Future<String> getOrCreateChat({
    required String applicationId,
    required String jobId,
    required String seekerId,
    required String recruiterId,
  }) async {
    return _firestoreService.getOrCreateChat(
      applicationId: applicationId,
      jobId: jobId,
      seekerId: seekerId,
      recruiterId: recruiterId,
    );
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    try {
      await _firestoreService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        receiverId: receiverId,
        text: text,
      );
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get messages stream
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestoreService.getMessages(chatId);
  }

  // Mark messages as read
  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestoreService.markMessagesAsRead(chatId, userId);
    } catch (e) {
      // ignore
    }
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
