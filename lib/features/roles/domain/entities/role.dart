/// A role with its assigned permission names.
class Role {
  const Role({required this.id, required this.name, required this.permissions});

  final String id;
  final String name;
  final List<String> permissions;

  factory Role.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A role returned by the API must have an id.',
      );
    }
    // Requiring relationship data avoids treating an incomplete API response
    // as a role with no permissions.
    if (!json.containsKey('permissions')) {
      throw const FormatException(
        'The roles API must return assigned permissions.',
      );
    }
    return Role(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      permissions: _requiredNames(json['permissions']),
    );
  }

  static List<String> _requiredNames(Object? values) {
    if (values is! List) {
      throw const FormatException(
        'The roles API must return permissions as a list.',
      );
    }
    return values
        .map(
          (value) => value is Map ? value['name']?.toString() ?? '' : '$value',
        )
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
