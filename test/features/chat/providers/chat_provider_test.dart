import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/features/chat/providers/chat_provider.dart';

void main() {
  group('ChatProvider', () {
    late ChatProvider chatProvider;

    setUp(() {
      chatProvider = ChatProvider();
    });

    tearDown(() {
      chatProvider.dispose();
    });

    test('initial state should be clean', () {
      expect(chatProvider.error, isNull);
    });

    test('sendMessage should handle errors gracefully', () async {
      // Without Firebase, this should handle the error internally
      await chatProvider.sendMessage(
        chatId: 'chat1',
        senderId: 's1',
        receiverId: 'r1',
        text: 'Hello!',
      );

      // Should not crash, may set error
      expect(chatProvider.error, isNotNull);
    });

    test('markAsRead should not throw', () async {
      // Should handle gracefully without Firebase
      await chatProvider.markAsRead('chat1', 'user1');
      // No assertion needed — just verifying no exception
    });
  });
}
