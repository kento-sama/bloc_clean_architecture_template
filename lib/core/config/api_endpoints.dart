/// Centralizes Laravel API paths so data sources use the same route contract.
class ApiEndpoints {
  // Prevent callers from creating instances; all members are static.
  const ApiEndpoints._();

  // Authentication endpoints live in one contract shared by the data source
  // and token-refresh interceptor.
  static const authLogin = '/auth/login';
  static const authRegister = '/auth/register';
  static const authCurrentUser = '/auth/me';
  static const authLogout = '/auth/logout';
  static const authRefresh = '/auth/refresh';
  static const authTwoFactor = '/auth/2fa';
  static const authTwoFactorChallenge = '$authTwoFactor/challenge';
  static const authTwoFactorSetup = '$authTwoFactor/setup';
  static const authTwoFactorConfirm = '$authTwoFactor/confirm';
  static const refreshTokenField = 'refresh_token';

  static const users = '/users';
  static String user(String id) => '$users/$id';
  static String userRoles(String id) => '${user(id)}/roles';
  static String userPermissions(String id) => '${user(id)}/permissions';

  static const roles = '/roles';
  static String role(String id) => '$roles/$id';
  static String rolePermissions(String id) => '${role(id)}/permissions';

  static const permissions = '/permissions';
  static String permission(String id) => '$permissions/$id';
}
