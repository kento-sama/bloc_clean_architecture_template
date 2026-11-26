/// Permission data needed by the UI, independent of the API response shape.
class Permission {
  const Permission({
    required this.id,
    required this.name,
    required this.guardName,
  });

  final String id;
  final String name;
  final String guardName;

  factory Permission.fromJson(Map<String, Object?> json) {
    // An id is required because update and delete endpoints address records by id.
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A permission returned by the API must have an id.',
      );
    }
    return Permission(
      id: id.toString(),
      name: json['name']?.toString() ?? '',
      guardName: json['guard_name']?.toString() ?? '',
    );
  }
}
