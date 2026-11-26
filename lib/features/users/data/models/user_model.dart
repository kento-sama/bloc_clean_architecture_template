import 'package:clean_bloc/features/users/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.roles,
    required super.directPermissions,
  });

  factory UserModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id == null) {
      throw const FormatException(
        'A user returned by the API must have an id.',
      );
    }
    if (!json.containsKey('roles') || !json.containsKey('direct_permissions')) {
      throw const FormatException(
        'The users API must return roles and direct_permissions separately.',
      );
    }
    return UserModel(
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

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'roles': roles,
    'direct_permissions': directPermissions,
  };
}
