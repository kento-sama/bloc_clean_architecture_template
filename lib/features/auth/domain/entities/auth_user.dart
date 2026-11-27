class AuthUser {
  // Domain entities describe app concepts and remain independent of HTTP,
  // Flutter widgets, secure storage, and state-management packages.
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.permissions,
    required this.roles,
    this.twoFactorEnabled = false,
  });

  final String id;
  final String name;
  final String email;
  final Set<String> permissions;
  final Set<String> roles;
  final bool twoFactorEnabled;

  bool get isSuperAdmin =>
      roles.any((role) => role.toLowerCase() == 'superadmin');

  /// Checks the permissions returned for this signed-in user.
  bool can(String permission) => permissions.contains(permission);

  /// Allows direct permissions and the global superadmin role.
  bool canAccess(String permission) => isSuperAdmin || can(permission);
}
