import 'package:clean_bloc/features/auth/domain/entities/auth_user.dart';

class AuthLoginResult {
  // A result can represent either a completed login or an OTP challenge.
  const AuthLoginResult.authenticated(AuthUser user)
    : this._(user: user, challengeToken: null);

  const AuthLoginResult.requiresTwoFactor(String challengeToken)
    : this._(user: null, challengeToken: challengeToken);

  const AuthLoginResult._({required this.user, required this.challengeToken});

  final AuthUser? user;
  final String? challengeToken;

  bool get requiresTwoFactor => challengeToken != null;
}
