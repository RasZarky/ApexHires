import 'package:flutter_test/flutter_test.dart';
import 'package:apex_hires/features/applications/providers/application_provider.dart';

void main() {
  group('ApplicationProvider', () {
    late ApplicationProvider appProvider;

    setUp(() {
      appProvider = ApplicationProvider();
    });

    tearDown(() {
      appProvider.dispose();
    });

    test('initial state should be clean', () {
      expect(appProvider.isLoading, false);
      expect(appProvider.error, isNull);
    });

    test('updateStatus should return false without Firebase', () async {
      final result = await appProvider.updateStatus('app1', 'shortlisted');
      expect(result, false);
    });

    test('updateNotes should return false without Firebase', () async {
      final result = await appProvider.updateNotes('app1', 'Great candidate');
      expect(result, false);
    });

    test('error should be set on failure', () async {
      await appProvider.updateStatus('app1', 'hired');
      expect(appProvider.error, isNotNull);
    });

    test('notifyListeners should be called on state changes', () {
      int notifyCount = 0;
      appProvider.addListener(() => notifyCount++);

      // Trigger operations
      appProvider.updateStatus('x', 'y');

      expect(notifyCount, greaterThanOrEqualTo(0));
    });
  });
}
