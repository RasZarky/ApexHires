import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('initial state should be not logged in', () {
      expect(authProvider.user, isNull);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.error, isNull);
    });

    test('signOut should clear user', () async {
      await authProvider.signOut();
      expect(authProvider.user, isNull);
      expect(authProvider.isLoggedIn, false);
    });

    test('notifyListeners should be called on signOut', () {
      int notifyCount = 0;
      authProvider.addListener(() => notifyCount++);

      authProvider.signOut();
      expect(notifyCount, greaterThan(0));
    });
  });
}
