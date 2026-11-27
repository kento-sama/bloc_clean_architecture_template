class TwoFactorSetup {
  // This domain entity carries only the information required for enrollment.
  const TwoFactorSetup({required this.secret, required this.provisioningUri});

  final String secret;
  final String provisioningUri;
}
