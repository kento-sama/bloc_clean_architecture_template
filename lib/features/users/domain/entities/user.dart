/// User administration data, keeping role grants separate from direct grants.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.directPermissions,
  });

  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final List<String> directPermissions;

  factory User.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A user returned by the API must have an id.',
      );
    }
    // Do not merge these fields: the UI manages inherited role access and
    // direct user grants independently.
    if (!json.containsKey('roles') || !json.containsKey('direct_permissions')) {
      throw const FormatException(
        'The users API must return roles and direct_permissions separately.',
      );
    }
    return User(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: _requiredNames(json['roles'], 'roles'),
      directPermissions: _requiredNames(
        json['direct_permissions'],
        'direct_permissions',
      ),
    );
  }

  static List<String> _requiredNames(Object? values, String field) {
    if (values is! List) {
      throw FormatException('The users API must return $field as a list.');
    }
    return values
        .map(
          (value) => value is Map ? value['name']?.toString() ?? '' : '$value',
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
