import 'package:clean_bloc/features/auth/domain/entities/two_factor_setup.dart';

class TwoFactorSetupModel extends TwoFactorSetup {
  // Validate enrollment data before it reaches the security UI.
  const TwoFactorSetupModel({
    required super.secret,
    required super.provisioningUri,
    super.recoveryCodes,
  });

  factory TwoFactorSetupModel.fromJson(Map<String, Object?> json) {
    final secret = json['secret'];
    final provisioningUri = json['provisioning_uri'] ?? json['qr_code_uri'];
    if (secret is! String ||
        secret.isEmpty ||
        provisioningUri is! String ||
        provisioningUri.isEmpty) {
      throw const FormatException(
        'The two-factor setup API must return secret and provisioning_uri.',
      );
    }
    final codes = json['recovery_codes'];
    return TwoFactorSetupModel(
      secret: secret,
      provisioningUri: provisioningUri,
      recoveryCodes: codes is List
          ? codes.map((code) => code.toString()).toList()
          : const [],
    );
  }
}
