import 'package:flutter_test/flutter_test.dart';
import 'package:time2wish_mobile/core/services/quick_action_service.dart';

void main() {
  group('QuickActionService Tests', () {
    test('sanitizePhoneNumber strips spaces, dashes and parentheses while preserving +', () {
      expect(QuickActionService.sanitizePhoneNumber('+33 6 12 34 56 78'), '+33612345678');
      expect(QuickActionService.sanitizePhoneNumber('+33 (0)6-12-34-56-78'), '+330612345678');
      expect(QuickActionService.sanitizePhoneNumber('06.12.34.56.78'), '0612345678');
      expect(QuickActionService.sanitizePhoneNumber('  +237 699 11 22 33  '), '+237699112233');
      expect(QuickActionService.sanitizePhoneNumber(''), '');
      expect(QuickActionService.sanitizePhoneNumber('   '), '');
    });

    test('sanitizePhoneNumber handles digits-only phone correctly', () {
      expect(QuickActionService.sanitizePhoneNumber('0123456789'), '0123456789');
      expect(QuickActionService.sanitizePhoneNumber('+18005550199'), '+18005550199');
    });
  });
}
