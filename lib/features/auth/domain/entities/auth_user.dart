class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.permissions,
    required this.roles,
  });

  final String id;
  final String name;
  final String email;
  final Set<String> permissions;
  final Set<String> roles;

  bool get isSuperAdmin =>
      roles.any((role) => role.toLowerCase() == 'superadmin');

  /// Checks the permissions returned for this signed-in user.
  bool can(String permission) => permissions.contains(permission);

  /// Allows direct permissions and the global superadmin role.
  bool canAccess(String permission) => isSuperAdmin || can(permission);
}
