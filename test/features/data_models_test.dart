import 'package:flutter_test/flutter_test.dart';
import 'package:clean_bloc/features/auth/data/models/auth_user_model.dart';
import 'package:clean_bloc/features/auth/data/models/two_factor_setup_model.dart';

void main() {
  group('Authentication API data models', () {
    test('AuthUserModel reads 2FA status', () {
      final model = AuthUserModel.fromJson({
        'id': 1,
        'name': 'Example User',
        'email': 'user@example.com',
        'permissions': [],
        'roles': [],
        'two_factor_enabled': true,
      });

      expect(model.twoFactorEnabled, isTrue);
    });

    test('AuthUserModel recognizes a confirmed timestamp', () {
      final model = AuthUserModel.fromJson({
        'id': 1,
        'name': 'Example User',
        'email': 'user@example.com',
        'permissions': [],
        'roles': [],
        'two_factor_confirmed_at': '2026-11-27T00:00:00Z',
      });

      expect(model.twoFactorEnabled, isTrue);
    });

    test('TwoFactorSetupModel maps activation details', () {
      final model = TwoFactorSetupModel.fromJson({
        'secret': 'JBSWY3DPEHPK3PXP',
        'provisioning_uri':
            'otpauth://totp/Example:user@example.test?secret=ABC',
        'recovery_codes': ['code-one', 'code-two'],
      });

      expect(model.secret, 'JBSWY3DPEHPK3PXP');
      expect(model.provisioningUri, startsWith('otpauth://totp/'));
      expect(model.recoveryCodes, ['code-one', 'code-two']);
    });

    test('TwoFactorSetupModel rejects incomplete setup data', () {
      expect(
        () => TwoFactorSetupModel.fromJson({'secret': 'JBSWY3DPEHPK3PXP'}),
        throwsFormatException,
      );
    });
  });
}
