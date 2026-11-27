class TwoFactorSetup {
  // This domain entity carries only the information required for enrollment.
  const TwoFactorSetup({
    required this.secret,
    required this.provisioningUri,
    this.recoveryCodes = const [],
  });

  final String secret;
  final String provisioningUri;
  final List<String> recoveryCodes;
}
