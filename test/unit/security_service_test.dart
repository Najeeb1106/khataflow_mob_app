import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata_app/core/services/security_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final Map<String, String> values = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'write':
          values[methodCall.arguments['key']] = methodCall.arguments['value'];
          return null;
        case 'read':
          return values[methodCall.arguments['key']];
        case 'delete':
          values.remove(methodCall.arguments['key']);
          return null;
        case 'deleteAll':
          values.clear();
          return null;
        case 'readAll':
          return values;
        case 'containsKey':
          return values.containsKey(methodCall.arguments['key']);
      }
      return null;
    });
  });

  setUp(() {
    values.clear();
  });

  group('SecurityService Recovery Tests', () {
    test('setupProfile saves hashed pin, question, and hashed normalized answer', () async {
      await SecurityService.setupProfile(
        name: 'John Doe',
        pin: '1234',
        enableFingerprint: false,
        recoveryQuestion: 'First School?',
        recoveryAnswer: '   BeaconHouse ',
      );

      final question = await SecurityService.getRecoveryQuestion();
      expect(question, equals('First School?'));

      // Verification of recovery answer with different casings and spacing
      final match1 = await SecurityService.verifyRecoveryAnswer('beaconhouse');
      expect(match1, isTrue);

      final match2 = await SecurityService.verifyRecoveryAnswer(' BEACONHOUSE   ');
      expect(match2, isTrue);

      final match3 = await SecurityService.verifyRecoveryAnswer('beaconhouse ');
      expect(match3, isTrue);
    });

    test('Incorrect answers increment failed attempts and trigger lockout after 5 tries', () async {
      await SecurityService.setupProfile(
        name: 'John Doe',
        pin: '1234',
        enableFingerprint: false,
        recoveryQuestion: 'Fav Color?',
        recoveryAnswer: 'Green',
      );

      expect(await SecurityService.isRecoveryLockedOut(), isFalse);
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(0));

      // 1st wrong attempt
      var res = await SecurityService.verifyRecoveryAnswer('Blue');
      expect(res, isFalse);
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(1));

      // 2nd wrong attempt
      res = await SecurityService.verifyRecoveryAnswer('Red');
      expect(res, isFalse);
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(2));

      // 3rd wrong attempt
      res = await SecurityService.verifyRecoveryAnswer('Black');
      expect(res, isFalse);

      // 4th wrong attempt
      res = await SecurityService.verifyRecoveryAnswer('Yellow');
      expect(res, isFalse);

      // 5th wrong attempt -> should trigger lockout
      res = await SecurityService.verifyRecoveryAnswer('White');
      expect(res, isFalse);
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(5));
      expect(await SecurityService.isRecoveryLockedOut(), isTrue);
      expect(await SecurityService.getRemainingLockoutTimeInSeconds(), greaterThan(0));

      // Additional attempts while locked out should immediately fail and not affect verify call
      res = await SecurityService.verifyRecoveryAnswer('Green'); // Correct answer but locked out
      expect(res, isFalse);
    });

    test('resetPin updates the PIN and clears lockout attempts', () async {
      await SecurityService.setupProfile(
        name: 'John Doe',
        pin: '1234',
        enableFingerprint: false,
        recoveryQuestion: 'Fav City?',
        recoveryAnswer: 'Karachi',
      );

      // Trigger some failed attempts
      await SecurityService.verifyRecoveryAnswer('Lahore');
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(1));

      // Reset PIN
      await SecurityService.resetPin('5678');

      // Verify attempts are reset
      expect(await SecurityService.getFailedRecoveryAttempts(), equals(0));

      // Verify PIN is updated
      expect(await SecurityService.verifyPin('5678'), isTrue);
      expect(await SecurityService.verifyPin('1234'), isFalse);
    });
  });
}
